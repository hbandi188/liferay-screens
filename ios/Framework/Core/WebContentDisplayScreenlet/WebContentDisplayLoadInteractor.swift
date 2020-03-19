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


class WebContentDisplayLoadInteractor: ServerReadOperationInteractor {

	var resultHTML: String?


	override func createOperation() -> LiferayWebContentLoadBaseOperation? {
		let screenlet = self.screenlet as! WebContentDisplayScreenlet

		let operation: LiferayWebContentLoadBaseOperation?

		if screenlet.articleId != "" {
			let articleIdOp = LiferayWebContentLoadFromArticleIdOperation()

			articleIdOp.articleId = screenlet.articleId

			operation = articleIdOp
		}
		else if screenlet.classPK != 0 {
			let classPKOp = LiferayWebContentLoadFromClassPKOperation()

			classPKOp.classPK = screenlet.classPK

			operation = classPKOp
		}
		else {
			operation = nil
		}

		if let operation = operation {
			operation.groupId = (screenlet.groupId != 0)
				? screenlet.groupId : LiferayServerContext.groupId
			operation.templateId = screenlet.templateId
		}

		return operation
	}

	override func completedOperation(op: ServerOperation) {
		self.resultHTML = (op as? LiferayWebContentLoadBaseOperation)?.resultHTML
	}

	override func readFromCache(op: ServerOperation, result: (AnyObject?) -> ()) {
		guard let cacheManager = SessionContext.currentCacheManager else {
			result(nil)
			return
		}

		if let loadOp = op as? LiferayWebContentLoadFromArticleIdOperation,
		   let groupId = loadOp.groupId,
		   let articleId = loadOp.articleId {

			cacheManager.getString(
                collection: ScreenletName(klass: WebContentDisplayScreenlet),
					key: articleCacheKey(groupId, articleId)) {
				loadOp.resultHTML = $0
				result($0)
			}
		}
		else {
			result(nil)
		}
	}

	override func writeToCache(op: ServerOperation) {
		guard let cacheManager = SessionContext.currentCacheManager else {
			return
		}

		if let loadOp = op as? LiferayWebContentLoadFromArticleIdOperation,
            let html = loadOp.resultHTML,
            let groupId = loadOp.groupId,
            let articleId = loadOp.articleId {

			cacheManager.setClean(
                collection: ScreenletName(klass: WebContentDisplayScreenlet),
				key: articleCacheKey(groupId, articleId),
				value: html,
				attributes: [
					"groupId": NSNumber(longLong: groupId),
					"articleId": articleId])
		}
	}

	private func articleCacheKey(groupId: Int64, _ articleId: String) -> String {
		return "\((groupId != 0) ? groupId : LiferayServerContext.groupId)-articleId-\(articleId)"
	}

}
