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
import Foundation

extension SyncManager {

	func userPortraitSynchronizer(
			key: String,
			attributes: [String:AnyObject])
			-> (Signal) -> () {

		{ signal in
			let userId = attributes["userId"] as! NSNumber

			self.cacheManager.getImage(
                collection: ScreenletName(klass: UserPortraitScreenlet.self),
					key: key) {

				if let image = $0 {
					let interactor = UploadUserPortraitInteractor(
						screenlet: nil,
                        userId: userId.int64Value,
						image: image)
					
                    self.prepareInteractorForSync(interactor: interactor,
						key: key,
						attributes: attributes,
						signal: signal,
                        screenletClassName: ScreenletName(klass: UserPortraitScreenlet.self))

					if !interactor.start() {
						signal()
					}
				}
				else {
                    self.delegate?.syncManager?(manager: self,
                                                onItemSyncScreenlet: ScreenletName(klass: UserPortraitScreenlet.self),
						failedKey: key,
						attributes: attributes,
                        error: NSError.errorWithCause(cause: .NotAvailable))

					signal()
				}
			}
		}
	}

}
