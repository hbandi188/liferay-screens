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

#if LIFERAY_SCREENS_FRAMEWORK
	import CryptoSwift
#endif


class DownloadUserPortraitInteractor: ServerReadOperationInteractor {

	private enum DownloadMode {
		case Attributes(portraitId: Int64, uuid: String, male: Bool)
		case EmailAddress(companyId: Int64, emailAddress: String)
		case ScreenName(companyId: Int64, screenName: String)
		case UserId(userId: Int64)

		var cacheKey: String {
			switch self {
			case .Attributes(let portraitId, _, _):
				return "portraitId-\(portraitId)"
			case .UserId(let userId):
				return "userId-\(userId)"
			case .EmailAddress(let companyId, let emailAddress):
				return "emailAddress-\(companyId)-\(emailAddress)"
			case .ScreenName(let companyId, let screenName):
				return "screenName-\(companyId)-\(screenName)"
			}
		}

		var cacheAttributes: [String:AnyObject] {
			switch self {
			case .Attributes(let portraitId, _, _):
                return ["portraitId": NSNumber(value: portraitId)]
			case .UserId(let userId):
                return ["userId": NSNumber(value: userId)]
			case .EmailAddress(let companyId, let emailAddress):
				return [
                    "companyId": NSNumber(value: companyId),
					"emailAddress": emailAddress as AnyObject]
			case .ScreenName(let companyId, let screenName):
				return [
                    "companyId": NSNumber(value: companyId),
					"screenName": screenName as AnyObject]
			}
		}
	}

	var resultImage: UIImage?
	var resultUserId: Int64?

	private let mode: DownloadMode


	init(screenlet: BaseScreenlet?, portraitId: Int64, uuid: String, male: Bool) {
		mode = DownloadMode.Attributes(portraitId: portraitId, uuid: uuid, male: male)

		super.init(screenlet: screenlet)
	}

	init(screenlet: BaseScreenlet?, userId: Int64) {
		mode = DownloadMode.UserId(userId: userId)

		super.init(screenlet: screenlet)
	}

	init(screenlet: BaseScreenlet?, companyId: Int64, emailAddress: String) {
		mode = DownloadMode.EmailAddress(companyId: companyId, emailAddress: emailAddress)

		super.init(screenlet: screenlet)
	}

	init(screenlet: BaseScreenlet?, companyId: Int64, screenName: String) {
		mode = DownloadMode.ScreenName(companyId: companyId, screenName: screenName)

		super.init(screenlet: screenlet)
	}

	override func createOperation() -> ServerOperation? {
		switch mode {
		case .Attributes(let portraitId, let uuid, let male):
			return createOperationFor(
				portraitId: portraitId,
				uuid: uuid,
				male: male)

		case .UserId(let userId):
            let currentUserId = SessionContext.userAttribute(key: "userId") as? NSNumber

            if userId == currentUserId?.int64Value {
				return createOperationForLogged()
			}
			else {
                return createOperationFor(loadUserOp: GetUserByUserIdOperation(userId: userId))
			}

		case .EmailAddress(let companyId, let emailAddress):
            let currentCompanyId = SessionContext.userAttribute(key: "companyId") as? NSNumber
            let currentEmailAddress = SessionContext.userAttribute(key: "emailAddress") as? NSString

			if companyId == currentCompanyId?.longLongValue
					&& emailAddress == currentEmailAddress {
				return createOperationForLogged()
			}
			else {
				return createOperationFor(
                    loadUserOp: GetUserByEmailOperation(
						companyId: companyId,
						emailAddress: emailAddress))
			}

		case .ScreenName(let companyId, let screenName):
            let currentCompanyId = SessionContext.userAttribute(key: "companyId") as? NSNumber
            let currentScreenName = SessionContext.userAttribute(key: "screenName") as? NSString

			if companyId == currentCompanyId?.longLongValue
					&& screenName == currentScreenName {
				return createOperationForLogged()
			}
			else {
				return createOperationFor(
                    loadUserOp: GetUserByScreenNameOperation(
						companyId: companyId,
						screenName: screenName))
			}
		}
	}

	override func completedOperation(op: ServerOperation) {
        if let httpOp = toHttpOperation(op: op),
		   let resultData = httpOp.resultData {
            resultImage = UIImage(data: resultData as Data)
		}
	}


	//MARK: Cache methods

	override func writeToCache(op: ServerOperation) {
		guard let cacheManager = SessionContext.currentCacheManager else {
			return
		}

        if let httpOp = toHttpOperation(op: op),
		   let resultData = httpOp.resultData {

			cacheManager.setClean(
                collection: ScreenletName(klass: UserPortraitScreenlet.self),
				key: mode.cacheKey,
				value: resultData,
				attributes: mode.cacheAttributes)
		}
	}

	override func readFromCache(op: ServerOperation, result: (AnyObject?) -> ()) {
		guard let cacheManager = SessionContext.currentCacheManager else {
			result(nil)
			return
		}

		func loadImageFromCache(output outputConnector: HttpOperation) {
			cacheManager.getImage(
                collection: ScreenletName(klass: UserPortraitScreenlet.self),
					key: self.mode.cacheKey) {
				if let image = $0 {
                    outputConnector.resultData = image.pngData() as NSData?
					outputConnector.lastError = nil
					result($0)
				}
				else {
					outputConnector.resultData = nil
                    outputConnector.lastError = NSError.errorWithCause(cause: .NotAvailable)
					result(nil)
				}
			}
		}


		if (op as? ServerOperationChain)?.currentOperation is GetUserBaseOperation {
			// asking for user attributes. if the image is cached, we'd need to skip this step

			cacheManager.getAny(
                collection: ScreenletName(klass: UserPortraitScreenlet.self),
					key: mode.cacheKey) {
				if $0 == nil {
					// not cached: continue
					result(nil)
				}
				else {
					// cached. Skip!

					// create a dummy HttpConnector to store the result
                    let dummyConnector = HttpOperation(url: NSURL(string: "http://dummy")! as URL)

					// set this dummy connector to allow "completedConnector" method retrieve the result
					(op as? ServerOperationChain)?.currentOperation = dummyConnector

					dispatch_async {
						loadImageFromCache(output: dummyConnector)
					}
				}
			}
		}
        else if let httpOp = toHttpOperation(op: op) {
			cacheManager.getAny(
                collection: ScreenletName(klass: UserPortraitScreenlet.self),
					key: mode.cacheKey) {
				guard let cachedObject = $0 else {
					httpOp.resultData = nil
                    httpOp.lastError = NSError.errorWithCause(cause: .NotAvailable)
					result(nil)
					return
				}

				if let data = cachedObject as? NSData {
					httpOp.resultData = data
					httpOp.lastError = nil
					result(httpOp)
				}
				else {
					dispatch_async {
						loadImageFromCache(output: httpOp)
					}
				}
			}
		}
		else {
			result(nil)
		}
	}


	//MARK: Private methods

	private func toHttpOperation(op: ServerOperation) -> HttpOperation? {
		return ((op as? ServerOperationChain)?.currentOperation as? HttpOperation)
			?? (op as? HttpOperation)
	}

	private func createOperationForLogged() -> ServerOperation? {
        if let portraitId = SessionContext.userAttribute(key: "portraitId") as? NSNumber,
            let uuid = SessionContext.userAttribute(key: "uuid") as? String {
				resultUserId = SessionContext.currentUserId

			return createOperationFor(
                portraitId: portraitId.int64Value,
				uuid: uuid,
				male: true)
		}

		return nil
	}

	private func createOperationFor(loadUserOp: GetUserBaseOperation) -> ServerOperation? {
		let chain = ServerOperationChain(head: loadUserOp)

		chain.onNextStep = { (op, seq) -> ServerOperation? in
			if let loadUserOp = op as? GetUserBaseOperation {
				return self.createOperationFor(attributes: loadUserOp.resultUserAttributes)
			}

			return nil
		}

		return chain
	}

    private func createOperationFor(attributes: [String:AnyObject]?) -> ServerOperation? {
		if let attributes = attributes,
		   let portraitId = attributes["portraitId"] as? NSNumber,
		   let uuid = attributes["uuid"] as? String,
		   let userId = attributes["userId"] as? NSNumber {

            resultUserId = userId.int64Value

			return createOperationFor(
                portraitId: portraitId.int64Value,
				uuid: uuid,
				male: true)
		}

		return nil
	}

    private func createOperationFor(portraitId: Int64, uuid: String, male: Bool) -> ServerOperation? {
		if let url = URLForAttributes(
				portraitId: portraitId,
				uuid: uuid,
				male: male) {
            return HttpOperation(url: url as URL)
		}

		return nil
	}

    private func URLForAttributes(portraitId: Int64, uuid: String, male: Bool) -> NSURL? {

		func encodedSHA1(input: String) -> String? {
			var result: String?
#if LIFERAY_SCREENS_FRAMEWORK
            if let inputData = input.data(using: String.Encoding.utf8,
					allowLossyConversion: false) {

				let resultBytes = CryptoSwift.Hash.sha1(inputData.arrayOfBytes()).calculate()
				let resultData = NSData(bytes: resultBytes)
				result = LRHttpUtil.encodeURL(resultData.base64EncodedStringWithOptions([]))
			}
#else
			var buffer = [UInt8](count: Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)

			CC_SHA1(input, CC_LONG(count(input)), &buffer)
			let data = NSData(bytes: buffer, length: buffer.count)
			let encodedString = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(0))

			result = LRHttpUtil.encodeURL(encodedString)
#endif
			return result
		}

        if let hashedUUID = encodedSHA1(input: uuid) {
			let maleString = male ? "male" : "female"

			let url = "\(LiferayServerContext.server)/image/user_\(maleString)/_portrait" +
				"?img_id=\(portraitId)" +
				"&img_id_token=\(hashedUUID)" +
			"&t=\(NSDate.timeIntervalSinceReferenceDate())"

			return NSURL(string: url)
		}
		
		return nil
	}

}
