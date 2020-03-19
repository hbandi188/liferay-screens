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


@objc public enum SyncConflictResolution: Int {

	case UseRemote
	case UseLocal
	case Discard
	case Ignore

}


@objc public protocol SyncManagerDelegate {

    @objc optional func syncManager(manager: SyncManager,
		itemsCount: UInt)

    @objc optional func syncManager(manager: SyncManager,
		onItemSyncScreenlet screenlet: String,
		startKey: String,
		attributes: [String:AnyObject])

    @objc optional func syncManager(manager: SyncManager,
		onItemSyncScreenlet screenlet: String,
		completedKey: String,
		attributes: [String:AnyObject])

    @objc optional func syncManager(manager: SyncManager,
		onItemSyncScreenlet screenlet: String,
		failedKey: String,
		attributes: [String:AnyObject],
		error: NSError)

    @objc optional func syncManager(manager: SyncManager,
		onItemSyncScreenlet screenlet: String,
		conflictedKey: String,
		remoteValue: AnyObject,
		localValue: AnyObject,
		resolve: (SyncConflictResolution) -> ())

}


public typealias OfflineSynchronizer = (String, [String:AnyObject]) -> (Signal) -> ()


@objc public class SyncManager: NSObject {

	public weak var delegate: SyncManagerDelegate?

	public let cacheManager: CacheManager

    private let syncQueue: OperationQueue
	private var synchronizers: [String:OfflineSynchronizer] = [:]


	public init(cacheManager: CacheManager) {
		self.cacheManager = cacheManager

        self.syncQueue = OperationQueue()
		self.syncQueue.maxConcurrentOperationCount = 1

		super.init()

        synchronizers[ScreenletName(klass: UserPortraitScreenlet.self)] =  userPortraitSynchronizer
        synchronizers[ScreenletName(klass: DDLFormScreenlet.self)] =  formSynchronizer
	}

	public func addSynchronizer(
			screenletClass: AnyClass,
            synchronizer: @escaping OfflineSynchronizer) {
        synchronizers[ScreenletName(klass: screenletClass)] = synchronizer
	}

	public func clear() {
		self.cacheManager.removeAll()
	}

	public func startSync() {
		cacheManager.countPendingToSync { count in
            self.delegate?.syncManager?(manager: self, itemsCount: count)

			if count > 0 {
				self.cacheManager.pendingToSync { (screenlet, key, attributes) -> Bool in
                    self.delegate?.syncManager?(manager: self, onItemSyncScreenlet: screenlet, startKey: key, attributes: attributes)
                    self.enqueueSyncForScreenlet(screenletName: screenlet, key, attributes)

					return true
				}
			}
		}
	}

	public func prepareInteractorForSync(
			interactor: ServerOperationInteractor,
			key: String,
			attributes: [String:AnyObject],
			signal: Signal,
			screenletClassName: String) {

		// this strategy saves the send date after the operation
		interactor.cacheStrategy = .CacheFirst

		interactor.onSuccess = {
            self.delegate?.syncManager?(manager: self,
				onItemSyncScreenlet: screenletClassName,
				completedKey: key,
				attributes: attributes)

			signal()
		}

		interactor.onFailure = { (err: NSError) in
            self.delegate?.syncManager?(manager: self,
				onItemSyncScreenlet: screenletClassName,
				failedKey: key,
				attributes: attributes,
				error: err)

			// TODO retry?
			signal()
		}
	}

	private func enqueueSyncForScreenlet(
			screenletName: String,
			_ key: String,
			_ attributes: [String:AnyObject]) {

		if let syncBuilder = synchronizers[screenletName] {
			let synchronizer = syncBuilder(key, attributes)
            syncQueue.addOperation(to_sync(function: synchronizer))
		}
	}

}
