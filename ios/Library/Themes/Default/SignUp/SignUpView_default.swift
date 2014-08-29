/**
* Copyright (c) 2000-present Liferay, Inc. All rights reserved.
*
* This library is free software; you can redistribute it and/or modify it under
* the terms of the GNU Lesser General Public License as published by the Free
* Software Foundation; either version 2.1 of the License, or (at your option)
* any later version.
*
* This library is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
* details.
*/
import UIKit

class SignUpView_default: SignUpView {

	@IBOutlet var emailAddressField: UITextField?
	@IBOutlet var passwordField: UITextField?
	@IBOutlet var firstNameField: UITextField?
	@IBOutlet var lastNameField: UITextField?
	@IBOutlet var signUpButton: UIButton?
	@IBOutlet var emailAddressBackground: UIImageView?
	@IBOutlet var passwordBackground: UIImageView?
	@IBOutlet var firstNameBackground: UIImageView?
	@IBOutlet var lastNameBackground: UIImageView?

	// MARK: Overriden setters

	override public func getEmailAddress() -> String {
		return emailAddressField!.text
	}

	override public func getPassword() -> String {
		return passwordField!.text
	}

	override public func getFirstName() -> String {
		return firstNameField!.text
	}

	override public func getLastName() -> String {
		return lastNameField!.text
	}

	// MARK: Overriden template methods

	override public func onStartOperation() {
		signUpButton!.enabled = false
	}

	override public func onFinishOperation() {
		signUpButton!.enabled = true
	}

	// MARK: BaseWidgetView

	override func becomeFirstResponder() -> Bool {
		return firstNameField!.becomeFirstResponder()
	}

	// MARK: UITextFieldDelegate

	func textFieldDidBeginEditing(textField: UITextField!) {
		emailAddressBackground!.highlighted = (textField == emailAddressField)
		passwordBackground!.highlighted = (textField == passwordField)
		firstNameBackground!.highlighted = (textField == firstNameField)
		lastNameBackground!.highlighted = (textField == lastNameField)
	}

}