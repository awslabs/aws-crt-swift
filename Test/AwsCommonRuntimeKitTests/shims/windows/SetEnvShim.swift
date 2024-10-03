import Foundation
import WinSDK

@discardableResult
func setenv(_ name: String, _ value: String, _ overwrite: Int) -> Int {
    let namePtr = name.withCString(encodedAs: UTF8.self) { $0 }
    let valuePtr = value.withCString(encodedAs: UTF8.self) { $0 }
    return SetEnvironmentVariableA(namePtr, valuePtr) ? 0 : -1
}

@discardableResult
func setenv(_ name: String, _ value: LPCSTR, _ overwrite: Int) -> Int {
    let namePtr = name.withCString(encodedAs: UTF8.self) { $0 }
    return SetEnvironmentVariableA(namePtr, value) ? 0 : -1
}

@discardableResult
func unsetenv(_ name: String) -> Int {
    let namePtr = name.withCString(encodedAs: UTF8.self) { $0 }
    return SetEnvironmentVariableA(namePtr, nil) ? 0 : -1
}