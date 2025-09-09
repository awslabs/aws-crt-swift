# Contains all of the classes that are shared across both the Canary Wrapper and the Persistent Canary Wrapper scripts
# If a class can/is reused, then it should be in this file.

# Needs to be installed prior to running
import boto3
import psutil
# Part of standard packages in Python 3.4+
import time
import os
import json
import subprocess
import zipfile
import datetime

# ================================================================================

# Class that holds metric data and has a few utility functions for getting that data in a format we can use for Cloudwatch


class DataSnapshot_Metric():
    def __init__(self, metric_name, metric_function, metric_dimensions=[],
                 metric_unit="None", metric_alarm_threshold=None, metric_alarm_severity=6,
                 git_hash="", git_repo_name="", reports_to_skip=0, is_percent=False):
        self.metric_name = metric_name
        self.metric_function = metric_function
        self.metric_dimensions = metric_dimensions
        self.metric_unit = metric_unit
        self.metric_alarm_threshold = metric_alarm_threshold
        self.metric_alarm_name = self.metric_name + "-" + git_repo_name + "-" + git_hash
        self.metric_alarm_description = 'Alarm for metric "' + \
            self.metric_name + '" - git hash: ' + git_hash
        self.metric_value = None
        self.reports_to_skip = reports_to_skip
        self.metric_alarm_severity = metric_alarm_severity
        self.is_percent = is_percent

    # Gets the latest metric value from the metric_function callback
    def get_metric_value(self, psutil_process: psutil.Process):
        if not self.metric_function is None:
            self.metric_value = self.metric_function(psutil_process)
        return self.metric_value

    # Returns the data needed to send to Cloudwatch when posting metrics
    def get_metric_cloudwatch_dictionary(self):
        if (self.reports_to_skip > 0):
            self.reports_to_skip -= 1
            return None  # skips sending to Cloudwatch

        if (self.metric_value == None):
            return None  # skips sending to Cloudwatch

        return {
            "MetricName": self.metric_name,
            "Dimensions": self.metric_dimensions,
            "Value": self.metric_value,
            "Unit": self.metric_unit
        }


class DataSnapshot_Dashboard_Widget():
    def __init__(self, widget_name, metric_namespace, metric_dimension, cloudwatch_region="us-east-1", widget_period=60) -> None:
        self.metric_list = []
        self.region = cloudwatch_region
        self.widget_name = widget_name
        self.metric_namespace = metric_namespace
        self.metric_dimension = metric_dimension
        self.widget_period = widget_period

    def add_metric_to_widget(self, new_metric_name):
        try:
            self.metric_list.append(new_metric_name)
        except Exception as e:
            print(
                "[DataSnapshot_Dashboard] ERROR - could not add metric to dashboard widget due to exception!")
            print("[DataSnapshot_Dashboard] Exception: " + str(e))

    def remove_metric_from_widget(self, existing_metric_name):
        try:
            self.metric_list.remove(existing_metric_name)
        except Exception as e:
            print(
                "[DataSnapshot_Dashboard] ERROR - could not remove metric from dashboard widget due to exception!")
            print("[DataSnapshot_Dashboard] Exception: " + str(e))

    def get_widget_dictionary(self):
        metric_list_json = []
        for metric_name in self.metric_list:
            metric_list_json.append(
                [self.metric_namespace, metric_name, self.metric_dimension, metric_name])

        return {
            "type": "metric",
            "properties": {
                "metrics": metric_list_json,
                "region": self.region,
                "title": self.widget_name,
                "period": self.widget_period,
            },
            "width": 14,
            "height": 10
        }

# ================================================================================

# Class that keeps track of the metrics registered, sets up Cloudwatch and S3, and sends periodic reports
# Is the backbone of the reporting operation


class DataSnapshot():
    def __init__(self,
                 git_hash=None,
                 git_repo_name=None,
                 git_hash_as_namespace=False,
                 git_fixed_namespace_text="mqtt5_canary",
                 datetime_string=None,
                 output_log_filepath=None,
                 output_to_console=True,
                 cloudwatch_region="us-east-1",
                 cloudwatch_make_dashboard=False,
                 cloudwatch_teardown_alarms_on_complete=True,
                 cloudwatch_teardown_dashboard_on_complete=True,
                 s3_bucket_name="canary-wrapper-bucket",
                 s3_bucket_upload_on_complete=True,
                 lambda_name="CanarySendEmailLambda",
                 metric_frequency=None):

        # Setting initial values
        # ==================
        self.first_metric_call = True
        self.metrics = []
        self.metrics_numbers = []
        self.metric_report_number = 0
        self.metric_report_non_zero_count = 4

        # Used to track if we initialize Cloudwatch alarms, etc.
        # Make sure we initialized the cloud watch alarms prior to sending the first metrics report.
        self.cloudwatch_initialization = False

        # Watched by the thread creating the snapshot. Will cause the thread(s) to abort and return an error.
        # These are for internal errors, for example: failed to fetch credentials, failed to setup metrics, and so on. This does not mean the canary failed or had error.
        self.abort_due_to_internal_error = False
        self.abort_due_to_internal_error_reason = ""
        self.abort_due_to_internal_error_due_to_credentials = False

        self.git_hash = None
        self.git_repo_name = None
        self.git_hash_as_namespace = git_hash_as_namespace
        self.git_fixed_namespace_text = git_fixed_namespace_text
        self.git_metric_namespace = None

        self.cloudwatch_region = cloudwatch_region
        self.cloudwatch_client = None
        self.cloudwatch_make_dashboard = cloudwatch_make_dashboard
        self.cloudwatch_teardown_alarms_on_complete = cloudwatch_teardown_alarms_on_complete
        self.cloudwatch_teardown_dashboard_on_complete = cloudwatch_teardown_dashboard_on_complete
        self.cloudwatch_dashboard_name = ""
        self.cloudwatch_dashboard_widgets = []

        self.s3_bucket_name = s3_bucket_name
        self.s3_client = None
        self.s3_bucket_upload_on_complete = s3_bucket_upload_on_complete

        self.output_filepath = output_log_filepath
        self.output_file = None
        self.output_to_console = output_to_console

        self.lambda_client = None
        self.lambda_name = lambda_name

        self.datetime_string = datetime_string
        self.metric_frequency = metric_frequency
        # ==================

        # Check for valid credentials
        # ==================
        try:
            tmp_sts_client = boto3.client('sts')
            tmp_sts_client.get_caller_identity()
        except Exception as e:
            print("[DataSnapshot] ERROR - AWS credentials are NOT valid!")
            self.abort_due_to_internal_error = True
            self.abort_due_to_internal_error_reason = "AWS credentials are NOT valid!"
            self.abort_due_to_internal_error_due_to_credentials = True
            return
        # ==================

        # Git related stuff
        # ==================
        if (git_hash == None or git_repo_name == None):
            print(
                "[DataSnapshot] ERROR - a Git hash and repository name are REQUIRED for the canary wrapper to run!")
            self.abort_due_to_internal_error = True
            self.abort_due_to_internal_error_reason = "No Git hash and repository passed!"
            return

        self.git_hash = git_hash
        self.git_repo_name = git_repo_name

        if (self.git_hash_as_namespace == False):
            self.git_metric_namespace = self.git_fixed_namespace_text
        else:
            if (self.datetime_string == None):
                git_namespace_prepend_text = self.git_repo_name + "-" + self.git_hash
            else:
                git_namespace_prepend_text = self.git_repo_name + \
                    "/" + self.datetime_string + "-" + self.git_hash
            self.git_metric_namespace = git_namespace_prepend_text
        # ==================

        # Cloudwatch related stuff
        # ==================
        try:
            self.cloudwatch_client = boto3.client(
                'cloudwatch', self.cloudwatch_region)
            self.cloudwatch_dashboard_name = self.git_metric_namespace
        except Exception as e:
            self.print_message(
                "[DataSnapshot] ERROR - could not make Cloudwatch client due to exception!")
            self.print_message("[DataSnapshot] Exception: " + str(e))
            self.cloudwatch_client = None
            self.abort_due_to_internal_error = True
            self.abort_due_to_internal_error_reason = "Could not make Cloudwatch client!"
            return
        # ==================

        # S3 related stuff
        # ==================
        try:
            self.s3_client = boto3.client("s3")
        except Exception as e:
            self.print_message(
                "[DataSnapshot] ERROR - could not make S3 client due to exception!")
            self.print_message("[DataSnapshot] Exception: " + str(e))
            self.s3_client = None
            self.abort_due_to_internal_error = True
            self.abort_due_to_internal_error_reason = "Could not make S3 client!"
            return
        # ==================

        # Lambda related stuff
        # ==================
        try:
            self.lambda_client = boto3.client("lambda", self.cloudwatch_region)
        except Exception as e:
            self.print_message(
                "[DataSnapshot] ERROR - could not make Lambda client due to exception!")
            self.print_message("[DataSnapshot] Exception: " + str(e))
            self.lambda_client = None
            self.abort_due_to_internal_error = True
            self.abort_due_to_internal_error_reason = "Could not make Lambda client!"
            return
        # ==================

        # File output (logs) related stuff
        # ==================
        if (self.output_filepath is not None):
            self.output_file = open(self.output_filepath, "w")
        # ==================

        self.print_message("[DataSnapshot] Data snapshot created!")

    # Cleans the class - closing any files, removing alarms, and sending data to S3.
    # Should be called at the end when you are totally finished shadowing metrics
    def cleanup(self, error_occurred=False):
        self._cleanup_cloudwatch_alarms()
        if (self.cloudwatch_make_dashboard == True):
            self._cleanup_cloudwatch_dashboard()

        self.print_message("[DataSnapshot] Data snapshot cleaned!")

        if (self.s3_bucket_upload_on_complete == True):
            self.export_result_to_s3_bucket(log_is_error=error_occurred)

        if (self.output_file is not None):
            self.output_file.close()
            self.output_file = None

    # Utility function for printing messages
    def print_message(self, message):
        self.output_file.write(message + "\n")
        if self.output_to_console == True:
            print(message, flush=True)

    # Utility function - adds the metric alarms to Cloudwatch. We do run this right before the first
    # collection of metrics so we can register metrics before we initialize Cloudwatch
    def _init_cloudwatch_pre_first_run(self):
        for metric in self.metrics:
            if (not metric.metric_alarm_threshold is None):
                self._add_cloudwatch_metric_alarm(metric)

        if (self.cloudwatch_make_dashboard == True):
            self._init_cloudwatch_pre_first_run_dashboard()

    # Utility function - adds the Cloudwatch Dashboard for the currently running data snapshot
    def _init_cloudwatch_pre_first_run_dashboard(self):
        try:
            # Remove the old dashboard if it exists before adding a new one
            self._cleanup_cloudwatch_dashboard()

            new_dashboard_widgets_array = []
            for widget in self.cloudwatch_dashboard_widgets:
                new_dashboard_widgets_array.append(
                    widget.get_widget_dictionary())

            new_dashboard_body = {
                "start": "-PT1H",
                "widgets": new_dashboard_widgets_array,
            }
            new_dashboard_body_json = json.dumps(new_dashboard_body)

            self.cloudwatch_client.put_dashboard(
                DashboardName=self.cloudwatch_dashboard_name,
                DashboardBody=new_dashboard_body_json)
            self.print_message(
                "[DataSnapshot] Added Cloudwatch dashboard successfully")
        except Exception as e:
            self.print_message(
                "[DataSnapshot] ERROR - Cloudwatch client could not make dashboard due to exception!")
            self.print_message("[DataSnapshot] Exception: " + str(e))
            self.abort_due_to_internal_error = True
            self.abort_due_to_internal_error_reason = "Cloudwatch client could not make dashboard due to exception"
            return

    # Utility function - The function that adds each individual metric alarm.
    def _add_cloudwatch_metric_alarm(self, metric):
        if self.cloudwatch_client is None:
            self.print_message(
                "[DataSnapshot] ERROR - Cloudwatch client not setup. Cannot register alarm")
            return

        try:
            self.cloudwatch_client.put_metric_alarm(
                AlarmName=metric.metric_alarm_name,
                AlarmDescription=metric.metric_alarm_description,
                MetricName=metric.metric_name,
                Namespace=self.git_metric_namespace,
                Statistic="Maximum",
                Dimensions=metric.metric_dimensions,
                Period=60,  # How long (in seconds) is an evaluation period?
                EvaluationPeriods=120,  # How many periods does it need to be invalid for?
                DatapointsToAlarm=1,  # How many data points need to be invalid?
                Threshold=metric.metric_alarm_threshold,
                ComparisonOperator="GreaterThanOrEqualToThreshold",
            )
        except Exception as e:
            self.print_message(
                "[DataSnapshot] ERROR - could not register alarm for metric due to exception: " + metric.metric_name)
            self.print_message("[DataSnapshot] Exception: " + str(e))

    # Utility function - removes all the Cloudwatch alarms for the metrics
    def _cleanup_cloudwatch_alarms(self):
        if (self.cloudwatch_teardown_alarms_on_complete == True):
            try:
                for metric in self.metrics:
                    if (not metric.metric_alarm_threshold is None):
                        self.cloudwatch_client.delete_alarms(
                            AlarmNames=[metric.metric_alarm_name])
            except Exception as e:
                self.print_message(
                    "[DataSnapshot] ERROR - could not delete alarms due to exception!")
                self.print_message("[DataSnapshot] Exception: " + str(e))

    # Utility function - removes all Cloudwatch dashboards created
    def _cleanup_cloudwatch_dashboard(self):
        if (self.cloudwatch_teardown_dashboard_on_complete == True):
            try:
                self.cloudwatch_client.delete_dashboards(
                    DashboardNames=[self.cloudwatch_dashboard_name])
                self.print_message(
                    "[DataSnapshot] Cloudwatch Dashboards deleted successfully!")
            except Exception as e:
                self.print_message(
                    "[DataSnapshot] ERROR - dashboard cleaning function failed due to exception!")
                self.print_message("[DataSnapshot] Exception: " + str(e))
                self.abort_due_to_internal_error = True
                self.abort_due_to_internal_error_reason = "Cloudwatch dashboard cleaning function failed due to exception"
                return

    # Returns the results of the metric alarms. Will return a list containing tuples with the following structure:
    # [Boolean (False = the alarm is in the ALARM state), String (Name of the alarm that is in the ALARM state), int (severity of alarm)]
    # Currently this function will only return a list of failed alarms, so if the returned list is empty, then it means all
    # alarms did not get to the ALARM state in Cloudwatch for the registered metrics
    def get_cloudwatch_alarm_results(self):
        return self._check_cloudwatch_alarm_states()

    # Utility function - collects the metric alarm results and returns them in a list.
    def _check_cloudwatch_alarm_states(self):
        return_result_list = []

        tmp = None
        for metric in self.metrics:
            tmp = self._check_cloudwatch_alarm_state_metric(metric)
            if (tmp[0] == False):
                return_result_list.append(tmp)

        return return_result_list

    # Utility function - checks each individual alarm and returns a tuple with the following format:
    # [Boolean (False if the alarm is in the ALARM state, otherwise it is true), String (name of the alarm), Int (severity of alarm)]
    def _check_cloudwatch_alarm_state_metric(self, metric):
        alarms_response = self.cloudwatch_client.describe_alarms_for_metric(
            MetricName=metric.metric_name,
            Namespace=self.git_metric_namespace,
            Dimensions=metric.metric_dimensions)

        return_result = [True, None, metric.metric_alarm_severity]

        for metric_alarm_dict in alarms_response["MetricAlarms"]:
            if metric_alarm_dict["StateValue"] == "ALARM":
                return_result[0] = False
                return_result[1] = metric_alarm_dict["AlarmName"]
                break

        return return_result

    # Exports a file with the same name as the commit Git hash to an S3 bucket in a folder with the Git repo name.
    # The function will upload the output log to s3, if there is no output log, then it will just upload a file with
    # the Git hash as the name
    def export_result_to_s3_bucket(self, log_is_error=False):
        if (self.s3_client is None):
            self.print_message(
                "[DataSnapshot] ERROR - No S3 client initialized! Cannot send log to S3")
            self.abort_due_to_internal_error = True
            self.abort_due_to_internal_error_reason = "S3 client not initialized and therefore cannot send log to S3"
            return

        is_s3_file_created = False
        s3_upload_log_file_path = self.output_filepath
        if (s3_upload_log_file_path is None):
            s3_upload_log_file_path = self.git_hash + ".log"

        # Might be useful for debugging?
        if (self.output_file != None):
            # Are we writing to output file? If so, then we do flush so everything is written to it
            self.output_file.flush()
        else:
            s3_file = open(s3_upload_log_file_path, "w")
            s3_file.write(self.git_hash)
            s3_file.close()
            is_s3_file_created = True

        # Upload to S3
        try:
            s3_path = None
            if (self.datetime_string == None):
                s3_path = self.git_repo_name + "/" + self.git_hash + ".log"
            else:
                s3_path = self.git_repo_name + "/" + \
                    self.datetime_string + "/" + self.git_hash + ".log"

            self.s3_client.upload_file(
                s3_upload_log_file_path, self.s3_bucket_name, s3_path)

            self.print_message("[DataSnapshot] Uploaded to S3!")

        except Exception as e:
            self.print_message(
                "[DataSnapshot] ERROR - could not upload to S3 due to exception!")
            self.print_message("[DataSnapshot] Exception: " + str(e))
            self.abort_due_to_internal_error = True
            self.abort_due_to_internal_error_reason = "S3 client had exception and therefore could not upload log!"

        if is_s3_file_created == True:
            os.remove(s3_upload_log_file_path)

        return

    # Sends an email via a special lambda. The payload has to contain a message and a subject
    # * (REQUIRED) message is the message you want to send in the body of the email
    # * (REQUIRED) subject is the subject that the email will be sent with
    def lambda_send_email(self, message, subject):

        payload = {"Message": message, "Subject": subject}
        payload_string = json.dumps(payload)

        try:
            self.lambda_client.invoke(
                FunctionName=self.lambda_name,
                InvocationType="Event",
                ClientContext="MQTT Wrapper Script",
                Payload=payload_string
            )
        except Exception as e:
            self.print_message(
                "[DataSnapshot] ERROR - could not send email via Lambda due to exception!")
            self.print_message("[DataSnapshot] Exception: " + str(e))
            self.abort_due_to_internal_error = True
            self.abort_due_to_internal_error_reason = "Lambda email function had an exception!"
            return

    # Registers a metric to be polled by the Snapshot.
    # * (REQUIRED) new_metric_name is the name of the metric. Cloudwatch will use this name
    # * (REQUIRED) new_metric_function is expected to be a pointer to a Python function and will not work if you pass a value/object
    # * (OPTIONAL) new_metric_unit is the metric unit. There is a list of possible metric unit types on the Boto3 documentation for Cloudwatch
    # * (OPTIONAL) new_metric_alarm_threshold is the value that the metric has to exceed in order to be registered as an alarm
    # * (OPTIONAL) new_reports_to_skip is the number of reports this metric will return nothing, but will get it's value.
    #     * Useful for CPU calculations that require deltas
    # * (OPTIONAL) new_metric_alarm_severity is the severity of the ticket if this alarm is triggered. A severity of 6+ means no ticket.
    # * (OPTIONAL) is_percent whether or not to display the metric as a percent when printing it (default=false)
    def register_metric(self, new_metric_name, new_metric_function, new_metric_unit="None",
                        new_metric_alarm_threshold=None, new_metric_reports_to_skip=0, new_metric_alarm_severity=6, is_percent=False):

        new_metric_dimensions = []

        if (self.git_hash_as_namespace == False):
            git_namespace_prepend_text = self.git_repo_name + "-" + self.git_hash
            new_metric_dimensions.append(
                {"Name": git_namespace_prepend_text, "Value": new_metric_name})
        else:
            new_metric_dimensions.append(
                {"Name": "System_Metrics", "Value": new_metric_name})

        new_metric = DataSnapshot_Metric(
            metric_name=new_metric_name,
            metric_function=new_metric_function,
            metric_dimensions=new_metric_dimensions,
            metric_unit=new_metric_unit,
            metric_alarm_threshold=new_metric_alarm_threshold,
            metric_alarm_severity=new_metric_alarm_severity,
            git_hash=self.git_hash,
            git_repo_name=self.git_repo_name,
            reports_to_skip=new_metric_reports_to_skip,
            is_percent=is_percent
        )
        self.metrics.append(new_metric)
        # append an empty list so we can track it's metrics over time
        self.metrics_numbers.append([])

    def register_dashboard_widget(self, new_widget_name, metrics_to_add=[], new_widget_period=60):

        # We need to know what metric dimension to get the metric(s) from
        metric_dimension_string = ""
        if (self.git_hash_as_namespace == False):
            metric_dimension_string = self.git_repo_name + "-" + self.git_hash
        else:
            metric_dimension_string = "System_Metrics"

        widget = self._find_cloudwatch_widget(name=new_widget_name)
        if (widget == None):
            widget = DataSnapshot_Dashboard_Widget(
                widget_name=new_widget_name, metric_namespace=self.git_metric_namespace,
                metric_dimension=metric_dimension_string,
                cloudwatch_region=self.cloudwatch_region,
                widget_period=new_widget_period)
            self.cloudwatch_dashboard_widgets.append(widget)

        for metric in metrics_to_add:
            self.register_metric_to_dashboard_widget(
                widget_name=new_widget_name, metric_name=metric)

    def register_metric_to_dashboard_widget(self, widget_name, metric_name, widget=None):
        if widget is None:
            widget = self._find_cloudwatch_widget(name=widget_name)
            if widget is None:
                print(
                    "[DataSnapshot] ERROR - could not find widget with name: " + widget_name, flush=True)
                return

        # Adjust metric name so it has the git hash, repo, etc
        metric_name_formatted = metric_name

        widget.add_metric_to_widget(new_metric_name=metric_name_formatted)
        return

    def remove_metric_from_dashboard_widget(self, widget_name, metric_name, widget=None):
        if widget is None:
            widget = self._find_cloudwatch_widget(name=widget_name)
            if widget is None:
                print(
                    "[DataSnapshot] ERROR - could not find widget with name: " + widget_name, flush=True)
                return
        widget.remove_metric_from_widget(existing_metric_name=metric_name)
        return

    def _find_cloudwatch_widget(self, name):
        result = None
        for widget in self.cloudwatch_dashboard_widgets:
            if widget.widget_name == name:
                return widget
        return result

    # Prints the metrics to the console
    def export_metrics_console(self):
        datetime_now = datetime.datetime.now()
        datetime_string = datetime_now.strftime("%d-%m-%Y/%H:%M:%S")

        self.print_message("\n[DataSnapshot] Metric report: " +
                           str(self.metric_report_number) + " (" + datetime_string + ")")
        for metric in self.metrics:
            if (metric.is_percent == True):
                self.print_message("    " + metric.metric_name +
                                   " - value: " + str(metric.metric_value) + "%")
            else:
                self.print_message("    " + metric.metric_name +
                                   " - value: " + str(metric.metric_value))
        self.print_message("")

    # Sends all registered metrics to Cloudwatch.
    # The function is called in post_metrics() to send the metrics. You should call post_metrics() for the monitor loop,
    # instead of using this function directly
    def export_metrics_cloudwatch(self):
        if (self.cloudwatch_client == None):
            self.print_message(
                "[DataSnapshot] Error - cannot export Cloudwatch metrics! Cloudwatch was not initialized.")
            self.abort_due_to_internal_error = True
            self.abort_due_to_internal_error_reason = "Could not export Cloudwatch metrics due to no Cloudwatch client initialized!"
            return

        self.print_message("[DataSnapshot] Preparing to send to Cloudwatch...")
        metrics_data = []
        metric_data_tmp = None
        for metric in self.metrics:
            metric_data_tmp = metric.get_metric_cloudwatch_dictionary()
            if (not metric_data_tmp is None):
                metrics_data.append(metric_data_tmp)

        if (len(metrics_data) == 0):
            self.print_message(
                "[DataSnapshot] INFO - no metric data to send. Skipping...")
            return

        try:
            self.cloudwatch_client.put_metric_data(
                Namespace=self.git_metric_namespace,
                MetricData=metrics_data)
            self.print_message("[DataSnapshot] Metrics sent to Cloudwatch.")
        except Exception as e:
            self.print_message(
                "[DataSnapshot] Error - something when wrong posting cloudwatch metrics!")
            self.print_message("[DataSnapshot] Exception: " + str(e))
            self.abort_due_to_internal_error = True
            self.abort_due_to_internal_error_reason = "Could not export Cloudwatch metrics due to exception in Cloudwatch client!"
            return

    # Call this at a set interval to post the metrics to Cloudwatch, etc.
    # This is the function you want to call repeatedly after you have everything setup.
    def post_metrics(self, psutil_process: psutil.Process):
        if (self.cloudwatch_initialization == False):
            self.cloudwatch_initialization = True
            self._init_cloudwatch_pre_first_run()

        # Update the metric values internally
        for i in range(0, len(self.metrics)):
            metric_value = self.metrics[i].get_metric_value(psutil_process)
            self.metrics_numbers[i].insert(0, metric_value)

            # Only keep the last metric_report_non_zero_count results
            if (len(self.metrics_numbers[i]) > self.metric_report_non_zero_count):
                amount_to_delete = len(
                    self.metrics_numbers[i]) - self.metric_report_non_zero_count
                del self.metrics_numbers[i][-amount_to_delete:]
            # If we have metric_report_non_zero_count amount of metrics, make sure there is at least one
            # non-zero. If it is all zero, then print a log so we can easily find it
            if (len(self.metrics_numbers[i]) == self.metric_report_non_zero_count):
                non_zero_found = False
                for j in range(0, len(self.metrics_numbers[i])):
                    if (self.metrics_numbers[i][j] != 0.0 and self.metrics_numbers[i][j] != None):
                        non_zero_found = True
                        break
                if (non_zero_found == False):
                    self.print_message("\n[DataSnapshot] METRIC ZERO ERROR!")
                    self.print_message(
                        f"[DataSnapshot] Metric index {i} has been zero for last {self.metric_report_non_zero_count} reports!")
                    self.print_message("\n")

        self.metric_report_number += 1

        self.export_metrics_console()
        self.export_metrics_cloudwatch()

    def output_diagnosis_information(self, dependencies_list):

        # Print general diagnosis information
        self.print_message(
            "\n========== Canary Wrapper diagnosis information ==========")
        self.print_message(
            "\nRunning Canary for repository: " + self.git_repo_name)
        self.print_message("\t Commit hash: " + self.git_hash)

        if not dependencies_list == "":
            self.print_message("\nDependencies:")
            dependencies_list = dependencies_list.split(";")
            dependencies_list_found_hash = False
            for i in range(0, len(dependencies_list)):
                # There's probably a better way to do this...
                if (dependencies_list_found_hash == True):
                    dependencies_list_found_hash = False
                    continue
                self.print_message("* " + dependencies_list[i])
                if (i+1 < len(dependencies_list)):
                    self.print_message("\t Commit hash: " +
                                       dependencies_list[i+1])
                    dependencies_list_found_hash = True
                else:
                    self.print_message("\t Commit hash: Unknown")

        if (self.metric_frequency != None):
            self.print_message("\nMetric Snapshot Frequency: " +
                               str(self.metric_frequency) + " seconds")
        self.print_message("\nMetrics:")
        for metric in self.metrics:
            self.print_message("* " + metric.metric_name)
            if metric.metric_alarm_threshold is not None:
                self.print_message("\t Alarm Threshold: " +
                                   str(metric.metric_alarm_threshold))
                self.print_message("\t Alarm Severity: " +
                                   str(metric.metric_alarm_severity))
            else:
                self.print_message("\t No alarm set for metric.")

        self.print_message("\n")
        self.print_message(
            "==========================================================")
        self.print_message("\n")

# ================================================================================


class SnapshotMonitor():
    def __init__(self, wrapper_data_snapshot, wrapper_metrics_wait_time, ticketing) -> None:

        self.data_snapshot = wrapper_data_snapshot
        self.had_internal_error = False
        self.error_due_to_credentials = False
        self.internal_error_reason = ""
        self.error_due_to_alarm = False
        self.ticketing = ticketing

        self.can_cut_ticket = False
        self.has_cut_ticket = False

        # A list of all the alarms triggered in the last check, cached for later
        # NOTE - this is only the alarm names! Not the severity. This just makes it easier to process
        self.cloudwatch_current_alarms_triggered = []

        # Check for errors
        if (self.data_snapshot.abort_due_to_internal_error == True):
            self.had_internal_error = True
            self.internal_error_reason = "Could not initialize DataSnapshot. Likely credentials are not setup!"
            if (self.data_snapshot.abort_due_to_internal_error_due_to_credentials == True):
                self.error_due_to_credentials = True
            self.data_snapshot.cleanup()
            return

        # Metric posting timer
        self.metric_post_timer_time = wrapper_metrics_wait_time
        self.next_metric_post_time = time.time() + wrapper_metrics_wait_time

    def register_metric(self, new_metric_name, new_metric_function, new_metric_unit="None", new_metric_alarm_threshold=None,
                        new_metric_reports_to_skip=0, new_metric_alarm_severity=6):

        try:
            self.data_snapshot.register_metric(
                new_metric_name=new_metric_name,
                new_metric_function=new_metric_function,
                new_metric_unit=new_metric_unit,
                new_metric_alarm_threshold=new_metric_alarm_threshold,
                new_metric_reports_to_skip=new_metric_reports_to_skip,
                new_metric_alarm_severity=new_metric_alarm_severity)
        except Exception as e:
            self.print_message(
                "[SnaptshotMonitor] ERROR - could not register metric in data snapshot due to exception!")
            self.print_message("[SnaptshotMonitor] Exception: " + str(e))
            self.had_internal_error = True
            self.internal_error_reason = "Could not register metric in data snapshot due to exception"
            return

    def register_dashboard_widget(self, new_widget_name, metrics_to_add=[], widget_period=60):
        self.data_snapshot.register_dashboard_widget(
            new_widget_name=new_widget_name, metrics_to_add=metrics_to_add, new_widget_period=widget_period)

    def output_diagnosis_information(self, dependencies=""):
        self.data_snapshot.output_diagnosis_information(
            dependencies_list=dependencies)

    # Validate if there are any new alarms that have been triggered since the last check,
    # if there is a new alarm, then cut a ticket if allowed.
    def check_alarms_for_new_alarms(self, triggered_alarms):

        if len(triggered_alarms) > 0:
            self.print_message(
                "WARNING - One or more alarms are in state of ALARM")

            old_alarms_still_active = []
            new_alarms = []
            new_alarms_highest_severity = 6
            new_alarm_found = True
            new_alarm_ticket_description = "Canary has metrics in ALARM state!\n\nMetrics in alarm:\n"

            for triggered_alarm in triggered_alarms:
                new_alarm_found = True

                # Is this a new alarm?
                for old_alarm_name in self.cloudwatch_current_alarms_triggered:
                    if (old_alarm_name == triggered_alarm[1]):
                        new_alarm_found = False
                        old_alarms_still_active.append(triggered_alarm[1])
                        new_alarm_ticket_description += "* (STILL IN ALARM) " + \
                            triggered_alarm[1] + "\n"
                        new_alarm_ticket_description += "\tSeverity: " + \
                            str(triggered_alarm[2])
                        new_alarm_ticket_description += "\n"
                        break

                # If it is a new alarm, then add it to our list so we can cut a new ticket
                if (new_alarm_found == True):
                    self.data_snapshot.print_message(
                        '    (NEW) Alarm with name "' + triggered_alarm[1] + '" is in the ALARM state!')
                    new_alarms.append(triggered_alarm[1])
                    if (triggered_alarm[2] < new_alarms_highest_severity):
                        new_alarms_highest_severity = triggered_alarm[2]
                    new_alarm_ticket_description += "* " + \
                        triggered_alarm[1] + "\n"
                    new_alarm_ticket_description += "\tSeverity: " + \
                        str(triggered_alarm[2])
                    new_alarm_ticket_description += "\n"

            if len(new_alarms) > 0:
                if (self.can_cut_ticket == True):
                    self.ticketing.cut_ticket_using_cloudwatch(
                        ticket_description="New metric(s) went into alarm for the Canary! Metrics in alarm: " + str(
                            new_alarm_ticket_description),
                        ticket_reason="New metric(s) went into alarm",
                        ticket_allow_duplicates=True,
                        ticket_severity=new_alarms_highest_severity)
                    self.has_cut_ticket = True
                    self.had_internal_error = True
                    self.internal_error_reason = "Metric(s) went into alarm state. Ticket cut."

            # Cache the new alarms and the old alarms
            self.cloudwatch_current_alarms_triggered = old_alarms_still_active + new_alarms

        else:
            self.cloudwatch_current_alarms_triggered.clear()

    def monitor_loop_function(self, psutil_process: psutil.Process):
        if self.had_internal_error:
            return

        # Check for data snapshot errors
        if self.data_snapshot.abort_due_to_internal_error:
            self.had_internal_error = True
            self.internal_error_reason = f"Data Snapshot error: {self.data_snapshot.abort_due_to_internal_error_reason}"
            return

        # Check alarms first
        try:
            triggered_alarms = self.data_snapshot.get_cloudwatch_alarm_results()
            self.check_alarms_for_new_alarms(triggered_alarms)
        except Exception as e:
            self.print_message(
                f"[SnapshotMonitor] ERROR checking alarms: {str(e)}")
            self.had_internal_error = True
            self.internal_error_reason = f"Alarm check failed: {str(e)}"
            return

        current_time = time.time()
        if current_time >= self.next_metric_post_time:
            # Post metrics
            try:
                self.data_snapshot.post_metrics(psutil_process)
                self.next_metric_post_time = current_time + self.metric_post_timer_time
            except Exception as e:
                self.print_message(
                    f"[SnapshotMonitor] ERROR posting metrics: {str(e)}")
                self.had_internal_error = True
                self.internal_error_reason = f"Metric posting failed: {str(e)}"
                return

    def send_email(self, email_body, email_subject_text_append=None):
        if (email_subject_text_append != None):
            self.data_snapshot.lambda_send_email(
                email_body, "Canary: " + self.data_snapshot.git_repo_name + ":" + self.data_snapshot.git_hash + " - " + email_subject_text_append)
        else:
            self.data_snapshot.lambda_send_email(
                email_body, "Canary: " + self.data_snapshot.git_repo_name + ":" + self.data_snapshot.git_hash)

    def stop_monitoring(self):
        # Stub - just added for consistency
        pass

    def start_monitoring(self):
        # Stub - just added for consistency
        pass

    def restart_monitoring(self):
        # Stub - just added for consistency
        pass

    def cleanup_monitor(self, error_occurred=False):
        self.data_snapshot.cleanup(error_occurred=error_occurred)

    def print_message(self, message):
        if (self.data_snapshot != None):
            self.data_snapshot.print_message(message)
        else:
            print(message, flush=True)

# ================================================================================


class ApplicationMonitor():
    def __init__(self, wrapper_application_path, wrapper_application_arguments, wrapper_application_restart_on_finish=True, data_snapshot=None) -> None:
        self.application_process = None
        self.application_process_psutil = None
        self.error_has_occurred = False
        self.error_due_to_credentials = False
        self.error_reason = ""
        self.error_code = 0
        self.wrapper_application_path = wrapper_application_path
        self.wrapper_application_arguments = wrapper_application_arguments
        self.wrapper_application_restart_on_finish = wrapper_application_restart_on_finish
        self.data_snapshot = data_snapshot

        self.stdout_file_path = "Canary_Stdout_File.txt"

    def start_monitoring(self):
        self.print_message(
            "[ApplicationMonitor] Starting to monitor application...")

        if (self.application_process == None):
            try:
                canary_command = self.wrapper_application_path + \
                    " " + self.wrapper_application_arguments
                self.application_process = subprocess.Popen(
                    canary_command + " | tee " + self.stdout_file_path, shell=True)
                self.application_process_psutil = psutil.Process(
                    self.application_process.pid)
                self.print_message(
                    "[ApplicationMonitor] Application started...")
            except Exception as e:
                self.print_message(
                    "[ApplicationMonitor] ERROR - Could not launch Canary/Application due to exception!")
                self.print_message("[ApplicationMonitor] Exception: " + str(e))
                self.error_has_occurred = True
                self.error_reason = "Could not launch Canary/Application due to exception"
                self.error_code = 1
                return
        else:
            self.print_message(
                "[ApplicationMonitor] ERROR - Monitor already has an application process! Cannot monitor two applications with one monitor class!")

    def restart_monitoring(self):
        self.print_message(
            "[ApplicationMonitor] Restarting monitor application...")

        if (self.application_process != None):
            try:
                self.stop_monitoring()
                self.start_monitoring()
                self.print_message(
                    "\n[ApplicationMonitor] Restarted monitor application!")
                self.print_message(
                    "================================================================================")
            except Exception as e:
                self.print_message(
                    "[ApplicationMonitor] ERROR - Could not restart Canary/Application due to exception!")
                self.print_message("[ApplicationMonitor] Exception: " + str(e))
                self.error_has_occurred = True
                self.error_reason = "Could not restart Canary/Application due to exception"
                self.error_code = 1
                return
        else:
            self.print_message(
                "[ApplicationMonitor] ERROR - Application process restart called but process is/was not running!")
            self.error_has_occurred = True
            self.error_reason = "Could not restart Canary/Application due to application process not being started initially"
            self.error_code = 1
            return

    def stop_monitoring(self):
        self.print_message(
            "[ApplicationMonitor] Stopping monitor application...")
        if (not self.application_process == None):
            self.application_process.terminate()
            self.application_process.wait()
            self.print_message(
                "[ApplicationMonitor] Stopped monitor application!")
            self.application_process = None
            self.print_stdout()
        else:
            self.print_message(
                "[ApplicationMonitor] ERROR - cannot stop monitor application because no process is found!")

    def print_stdout(self):
        # Print the STDOUT file
        if (os.path.isfile(self.stdout_file_path)):
            self.print_message("Just finished Application STDOUT: ")
            with open(self.stdout_file_path, "r") as stdout_file:
                self.print_message(stdout_file.read())
            os.remove(self.stdout_file_path)

    def monitor_loop_function(self):
        if (self.application_process != None):

            application_process_return_code = None
            try:
                application_process_return_code = self.application_process.poll()
            except Exception as e:
                self.print_message(
                    "[ApplicationMonitor] ERROR - exception occurred while trying to poll application status!")
                self.print_message("[ApplicationMonitor] Exception: " + str(e))
                self.error_has_occurred = True
                self.error_reason = "Exception when polling application status"
                self.error_code = 1
                return

            # If it is not none, then the application finished
            if (application_process_return_code != None):

                self.print_message(
                    "[ApplicationMonitor] Monitor application has stopped! Processing result...")

                if (application_process_return_code != 0):
                    self.print_message(
                        "[ApplicationMonitor] ERROR - Something Crashed in Canary/Application!")
                    self.print_message(
                        "[ApplicationMonitor] Error code: " + str(application_process_return_code))

                    self.error_has_occurred = True
                    self.error_reason = "Canary application crashed!"
                    self.error_code = application_process_return_code
                else:
                    # Should we restart?
                    if (self.wrapper_application_restart_on_finish == True):
                        self.print_message(
                            "[ApplicationMonitor] NOTE - Canary finished running and is restarting...")
                        self.restart_monitoring()
                    else:
                        self.print_message(
                            "[ApplicationMonitor] Monitor application has stopped and monitor is not supposed to restart... Finishing...")
                        self.error_has_occurred = True
                        self.error_reason = "Canary Application Finished"
                        self.error_code = 0
            else:
                self.print_message(
                    "[ApplicationMonitor] Monitor application is still running...")

    def cleanup_monitor(self, error_occurred=False):
        pass

    def print_message(self, message):
        if (self.data_snapshot != None):
            self.data_snapshot.print_message(message)
        else:
            print(message, flush=True)


# The class used to cut tickets to SIM using a temporary Cloudwatch metric that is quickly created, triggered,
# and destroyed the cloudwatch alarm afterwards.
# Can be called in any thread - creates its own Cloudwatch client and any data it needs is passed in.
#
# See (https://w.amazon.com/bin/view/CloudWatchAlarms/Internal/CloudWatchAlarmsSIMTicketing) for more details
# on how the alarm is sent using Cloudwatch.
#
# We cut the ticket use a temporary "faked" Cloudwatch alarm, so we dont mess the alarm across the canary runs.
# If we used the actual metrics alarm, then the alarm might be in the ALARM state from previous runs and would
# not reflect the current state of the canary.
class CloudwatchTicketing():
    def __init__(self,
                 git_repo_name,
                 git_hash,
                 git_hash_as_namespace,
                 git_fixed_namespace_text,
                 ticket_category,
                 ticket_type,
                 ticket_item,
                 ticket_group,
                 cloudwatch_region):
        self.ticket_category = ticket_category
        self.ticket_type = ticket_type
        self.ticket_item = ticket_item
        self.ticket_group = ticket_group
        self.cloudwatch_region = cloudwatch_region

        self.cloudwatch_regiongit_metric_namespace = ""
        if (git_hash_as_namespace == False):
            self.git_metric_namespace = git_fixed_namespace_text
        else:
            git_namespace_prepend_text = git_repo_name + "-" + git_hash
            self.git_metric_namespace = git_namespace_prepend_text

        self.ticket_alarm_name = git_repo_name + "-" + git_hash + "-AUTO-TICKET"
        self.new_metric_dimensions = []
        if (git_hash_as_namespace == False):
            git_namespace_prepend_text = git_repo_name + "-" + git_hash
            self.new_metric_dimensions.append(
                {"Name": git_namespace_prepend_text, "Value": self.ticket_alarm_name})
        else:
            self.new_metric_dimensions.append(
                {"Name": "System_Metrics", "Value": self.ticket_alarm_name})

    def cut_ticket_using_cloudwatch(self,
                                    ticket_description,
                                    ticket_reason,
                                    ticket_severity=5,
                                    ticket_allow_duplicates=False):
        try:
            cloudwatch_client = boto3.client(
                'cloudwatch', self.cloudwatch_region)
        except Exception as e:
            print(
                "ERROR - could not create Cloudwatch client to make ticket metric alarm due to exception!")
            print("Exception: " + str(e), flush=True)
            return

        ticket_arn = f"arn:aws:cloudwatch::cwa-internal:ticket:{ticket_severity}:{self.ticket_category}:{self.ticket_type}:{self.ticket_item}:{self.ticket_group}:"
        if (ticket_allow_duplicates == True):
            # use "DO-NOT-DEDUPE" so we can run the same commit again and it will cut another ticket.
            ticket_arn += "DO-NOT-DEDUPE"
        # In the ticket ARN, all spaces need to be replaced with +
        ticket_arn = ticket_arn.replace(" ", "+")

        ticket_alarm_description = f"AUTO CUT CANARY WRAPPER TICKET\n\nREASON: {ticket_reason}\n\nDESCRIPTION: {ticket_description}\n\n"

        # Register a metric alarm so it can auto-cut a ticket for us
        try:
            cloudwatch_client.put_metric_alarm(
                AlarmName=self.ticket_alarm_name,
                AlarmDescription=ticket_alarm_description,
                MetricName=self.ticket_alarm_name,
                Namespace=self.git_metric_namespace,
                Statistic="Maximum",
                Dimensions=self.new_metric_dimensions,
                Period=60,  # How long (in seconds) is an evaluation period?
                EvaluationPeriods=1,  # How many periods does it need to be invalid for?
                DatapointsToAlarm=1,  # How many data points need to be invalid?
                Threshold=1,
                ComparisonOperator="GreaterThanOrEqualToThreshold",
                # The data above does not really matter - it just needs to be valid input data.
                # This is the part that tells Cloudwatch to cut the ticket
                AlarmActions=[ticket_arn]
            )
        except Exception as e:
            print("ERROR - could not create ticket metric alarm due to exception!")
            print("Exception: " + str(e), flush=True)
            return

        # Trigger the alarm so it cuts the ticket
        try:
            cloudwatch_client.set_alarm_state(
                AlarmName=self.ticket_alarm_name,
                StateValue="ALARM",
                StateReason="AUTO TICKET CUT")
        except Exception as e:
            print("ERROR - could not cut ticket due to exception!")
            print("Exception: " + str(e), flush=True)
            return

        print("Waiting for ticket metric to trigger...", flush=True)
        # Wait a little bit (2 seconds)...
        time.sleep(2)

        # Remove the metric
        print("Removing ticket metric...", flush=True)
        cloudwatch_client.delete_alarms(AlarmNames=[self.ticket_alarm_name])

        print("Finished cutting ticket via Cloudwatch!", flush=True)
        return
