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


@objc public protocol SignUpScreenletDelegate : BaseScreenletDelegate {

    @objc optional func screenlet(screenlet: SignUpScreenlet,
			onSignUpResponseUserAttributes attributes: [String:AnyObject])

    @objc optional func screenlet(screenlet: SignUpScreenlet,
			onSignUpError error: NSError)

}


@IBDesignable public class SignUpScreenlet: BaseScreenlet, AnonymousBasicAuthType {

	//MARK: Inspectables

	@IBInspectable public var anonymousApiUserName: String? = "test@liferay.com"
	@IBInspectable public var anonymousApiPassword: String? = "test"

	@IBInspectable public var autoLogin: Bool = true

	@IBInspectable public var saveCredentials: Bool = true

	@IBInspectable public var companyId: Int64 = 0

	@IBOutlet public weak var autoLoginDelegate: LoginScreenletDelegate?


	public var signUpDelegate: SignUpScreenletDelegate? {
		return delegate as? SignUpScreenletDelegate
	}

	public var viewModel: SignUpViewModel {
		return screenletView as! SignUpViewModel
	}

	public func loadCurrentUser() -> Bool {
		if SessionContext.isLoggedIn {
			self.viewModel.editCurrentUser = true
			return true
		}
		return false
	}


	//MARK: BaseScreenlet

	override public func createInteractor(name: String, sender: AnyObject?) -> Interactor? {

		switch name {
		case "signup-action":
			return createSignUpInteractor()
		case "save-action":
			return createSaveInteractor()
		default:
			return nil
		}
	}

	private func createSignUpInteractor() -> SignUpInteractor {
		let interactor = SignUpInteractor(screenlet: self)

		interactor.onSuccess = {
            self.signUpDelegate?.screenlet?(screenlet: self,
					onSignUpResponseUserAttributes: interactor.resultUserAttributes!)

			if self.autoLogin {
                self.doAutoLogin(userAttributes: interactor.resultUserAttributes!)

				if self.saveCredentials {
					SessionContext.removeStoredCredentials()

					if SessionContext.storeCredentials() {
                        self.autoLoginDelegate?.onScreenletCredentialsSaved?(screenlet: self)
					}
				}
			}
		}

		interactor.onFailure = {
            self.signUpDelegate?.screenlet?(screenlet: self, onSignUpError: $0)
			return
		}

		return interactor
	}

	private func createSaveInteractor() -> SaveUserInteractor {
		let interactor = SaveUserInteractor(screenlet: self)

		interactor.onSuccess = {
			if SessionContext.isLoggedIn {
				// refresh current session
                self.doAutoLogin(userAttributes: interactor.resultUserAttributes!)
			}

            self.signUpDelegate?.screenlet?(screenlet: self,
					onSignUpResponseUserAttributes: interactor.resultUserAttributes!)
		}

		interactor.onFailure = {
            self.signUpDelegate?.screenlet?(screenlet: self, onSignUpError: $0)
		}

		return interactor
	}

	private func doAutoLogin(userAttributes: [String:AnyObject]) {
		let userNameKeys : [BasicAuthMethod:String] = [
			.Email : "emailAddress",
			.ScreenName : "screenName",
			.UserId: "userId"
		]

        let currentAuth = BasicAuthMethod.fromUserName(userName: anonymousApiUserName!)

		if let currentKey = userNameKeys[currentAuth],
				let userName = userAttributes[currentKey] as? String {

			SessionContext.createBasicSession(
				username: userName,
				password: self.viewModel.password!,
				userAttributes: userAttributes)

            self.autoLoginDelegate?.screenlet?(screenlet: self,
				onLoginResponseUserAttributes: userAttributes)
		}
	}

}
