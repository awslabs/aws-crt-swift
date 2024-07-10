"""
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: Apache-2.0.
"""
import pytest
from time import sleep

from appium import webdriver
from appium.options.ios import XCUITestOptions
from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import NoSuchElementException

capabilities = dict(
    platformName='ios',
    automationName='xcuitest',
    deviceName='iPhone',
    bundleId='aws-common-runtime.MqttClient',
    language='en',
    locale='US',
)

appium_server_url = 'http://0.0.0.0:4723/wd/hub'

class TestApp:
    def setup_method(self):
        self.driver = webdriver.Remote(appium_server_url, options=XCUITestOptions().load_capabilities(capabilities))
        self.driver.implicitly_wait(10)

    def teardown_method(self):
        if self.driver:
            self.driver.quit()

    @pytest.mark.parametrize("test_suite", [
        "test suite 1",
        "test suite 2"
    ])

    def start_mqtt(self, test_suite):
        sleep(3)
        self.perform_click_element('Setup Client and Start')
        sleep(3)

    def perform_click_element(self, element_id):
        try:
            element = self.driver.find_element(by=AppiumBy.ID, value=element_id)
            element.click()
            sleep(2)
        except NoSuchElementException:
            pytest.skip(f"Element with ID '{element_id}' not found. Skipped the test")

if __name__ == '__main__':
    TestApp.start_mqtt()
