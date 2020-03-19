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


@objc public class ServerOperation: Operation {

	private struct OperationsQueue {

        static private var queue: OperationQueue?

		static func addOperation(operation: ServerOperation) {
			if queue == nil {
                queue = OperationQueue()
				queue!.maxConcurrentOperationCount = 1
			}

			queue!.addOperation(operation)
		}

	}

	public var lastError: Error?

	internal var onComplete: ((ServerOperation) -> Void)?


	//MARK: NSOperation

	public override func main() {
        if isCancelled {
            lastError = NSError.errorWithCause(cause: .Cancelled)
		}
		else {
			if preRun() {
				if let session = createSession() {
					doRun(session: session)
					postRun()
				}
				else {
                    lastError = NSError.errorWithCause(cause: .NotAvailable)
				}
			}
			else {
                lastError = NSError.errorWithCause(cause: .AbortedDueToPreconditions)
			}
		}

		callOnComplete()
	}


	//MARK: Public methods

	public func validateAndEnqueue(onComplete: ((ServerOperation) -> Void)? = nil) -> ValidationError? {
		let error = validateData()

		if error == nil {
            enqueue(onComplete: onComplete)
		}

		return error
	}

	public func enqueue(onComplete: ((ServerOperation) -> Void)? = nil) {
		if onComplete != nil {
			self.onComplete = onComplete
		}

        OperationsQueue.addOperation(operation: self)
	}


	//MARK: Template methods

	public func validateData() -> ValidationError? {
		// Do not add any code here. Children classes may not call super
		nil
	}

	public func preRun() -> Bool {
		// Do not add any code here. Children classes may not call super
		true
	}

	public func doRun(session: LRSession) {
		// Do not add any code here. Children classes may not call super
	}

	public func postRun() {
		// Do not add any code here. Children classes may not call super
	}

	public func createSession() -> LRSession? {
		if !SessionContext.isLoggedIn {
            lastError = NSError.errorWithCause(cause: .AbortedDueToPreconditions,
					message: "Login required to use this operation")

			return nil
		}

		return SessionContext.createSessionFromCurrentSession()
	}

	public func callOnComplete() {
		if self.onComplete != nil {
			dispatch_main {
				self.onComplete!(self)

				// this breaks the retain cycle between the op and 'onComplete'
				self.onComplete = nil
			}
		}
	}

}
