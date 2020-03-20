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


public class DDLFormTableView: DDLFormView,
UITableViewDataSource, UITableViewDelegate, KeyboardLayoutable {
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }
    

	@IBOutlet public var tableView: UITableView?

	override public var record: DDLRecord? {
		didSet {
			if cellHeights.isEmpty {
				registerFieldCells()
			}

			forEachField() {
                self.registerCustomEditor(field: $0)
                self.resetCellHeightForField(field: $0)
			}

			refresh()
		}
	}

	override public var themeName: String {
		didSet {
			registerFieldCells()
		}
	}

	internal var firstCellResponder: UIResponder?

	internal var cellHeights: [String : (registered:CGFloat, current:CGFloat)] = [:]
	internal var submitButtonHeight: CGFloat = 0.0

	internal var originalFrame: CGRect?
	internal var keyboardManager = KeyboardManager()


	//MARK: DDLFormView

	override public func refresh() {
		tableView!.reloadData()
	}

	override public func resignFirstResponder() -> Bool {
		var result = false

		if let cellValue = firstCellResponder {
			result = cellValue.resignFirstResponder()
			if result {
				firstCellResponder = nil
			}
		}

		return result
	}

	override public func becomeFirstResponder() -> Bool {
		var result = false

        let rowCount = tableView!.numberOfRows(inSection: 0)
        var indexPath = NSIndexPath(row: 0, section: 0)

		while !result && indexPath.row < rowCount {
            if let cell = tableView!.cellForRow(at: indexPath as IndexPath) {
                if cell.canBecomeFirstResponder {
					result = cell.becomeFirstResponder()
				}
			}

			indexPath = NSIndexPath(
					forRow: indexPath.row.successor(),
					inSection: indexPath.section)
		}

		return result
	}

	override public func onShow() {
        keyboardManager.registerObserver(layoutable: self)
	}

	override public func onHide() {
		keyboardManager.unregisterObserver()
	}

	override internal func showField(field: DDLField) {
        if let row = getFieldIndex(field: field) {
            tableView!.scrollToRow(
                at: NSIndexPath(row: row, section: 0) as IndexPath,
                at: .top, animated: true)
		}
	}

	override internal func changeDocumentUploadStatus(field: DDLFieldDocument) {
        if let row = getFieldIndex(field: field) {
            if let cell = tableView!.cellForRow(
                at: NSIndexPath(row: row, section: 0) as IndexPath) as? DDLFieldTableCell {
                cell.changeDocumentUploadStatus(field: field)
			}
		}
	}


	//MARK: KeyboardLayoutable

	public func layoutWhenKeyboardShown(keyboardHeight: CGFloat,
			animation:(time: NSNumber, curve: NSNumber)) {

        let cell = DDLFieldTableCell.viewAsFieldCell(view: firstCellResponder as? UIView)

		var scrollDone = false
		let scrollClosure = { (completedAnimation: Bool) -> Void in
			if let cellValue = cell {
				if !cellValue.isFullyVisible {
                    cellValue.tableView!.scrollToRow(at: cellValue.indexPath! as IndexPath,
                                                     at: .middle,
							animated: true)
				}
			}
		}

		if let textInput = firstCellResponder as? UITextInputTraits {

			var shouldWorkaroundUIPickerViewBug = false
			if let cellValue = cell {
				shouldWorkaroundUIPickerViewBug =
						cellValue.field!.editorType == DDLField.Editor.Document ||
						cellValue.field!.editorType == DDLField.Editor.Select
			}

			if shouldWorkaroundUIPickerViewBug {
				//FIXME
				// Height used by UIPickerView is 216, when the standard keyboard have 253
				keyboardHeight = 253
			}
            else if textInput.autocorrectionType == UITextAutocorrectionType.default ||
                textInput.autocorrectionType == UITextAutocorrectionType.yes {

				keyboardHeight += KeyboardManager.defaultAutocorrectionBarHeight
			}

            let absoluteFrame = adjustRectForCurrentOrientation(rect: convert(frame, to: window!))
            let screenHeight = adjustRectForCurrentOrientation(rect: UIScreen.main.bounds).height

			if (absoluteFrame.origin.y + absoluteFrame.size.height >
					screenHeight - keyboardHeight) || originalFrame != nil {

				let newHeight = screenHeight - keyboardHeight + absoluteFrame.origin.y

				if Int(newHeight) != Int(self.frame.size.height) {
					if originalFrame == nil {
						originalFrame = frame
					}

					scrollDone = true

                    UIView.animate(withDuration: animation.time.doubleValue,
							delay: 0,
                            options: UIView.AnimationOptions(rawValue: animation.curve.unsignedLongValue),
							animations: {
								self.frame = CGRectMake(
										self.frame.origin.x,
										self.frame.origin.y,
										self.frame.size.width,
										newHeight)
							},
							completion: scrollClosure)
				}
			}
		}

		if !scrollDone {
			scrollClosure(true)
		}
	}

	public func layoutWhenKeyboardHidden() {
		if let originalFrameValue = originalFrame {
			self.frame = originalFrameValue
			originalFrame = nil
		}
	}


	//MARK: UITableViewDataSource

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if isRecordEmpty {
			return 0
		}

		return record!.fields.count + (showSubmitButton ? 1 : 0)
	}

	public func tableView(tableView: UITableView,
			cellForRowAtIndexPath indexPath: NSIndexPath)
			-> UITableViewCell {

		var cell:DDLFieldTableCell?
		let row = indexPath.row

		if row == record!.fields.count {
            cell = tableView.dequeueReusableCell(withIdentifier: "SubmitButton")
					as? DDLFieldTableCell

			cell!.formView = self
		}
        else if let field = getField(index: row) {
            cell = tableView.dequeueReusableCell(withIdentifier: field.name)
					as? DDLFieldTableCell

			if cell == nil {
                cell = tableView.dequeueReusableCell(
                    withIdentifier: field.editorType.toCapitalizedName()) as? DDLFieldTableCell
			}

			if let cellValue = cell {
				cellValue.formView = self
				cellValue.tableView = tableView
				cellValue.indexPath = indexPath
				cellValue.field = field
			}
			else {
				print("ERROR: Cell XIB is not registerd for type \(field.editorType.toCapitalizedName())\n")
			}
		}

		return cell!
	}

	public func tableView(tableView: UITableView,
			heightForRowAtIndexPath indexPath: NSIndexPath)
			-> CGFloat {

		let row = indexPath.row

                return (row == record!.fields.count) ? submitButtonHeight : cellHeightForField(field: getField(index: row)!)
	}


	//MARK: Internal methods

	internal func registerFieldCells() {
        let bundles = Bundle.allBundles(type(of: self));

		for fieldEditor in DDLField.Editor.all() {
			for bundle in bundles {
				let cellId = fieldEditor.toCapitalizedName()

				if let cellView = registerEditorCellInBundle(bundle,
						nibName: "DDLField\(cellId)TableCell",
						cellId: cellId) {
					cellHeights[cellId] = (cellView.bounds.size.height, cellView.bounds.size.height)

					break
				}
			}
		}

		if showSubmitButton {
			for bundle in bundles {
				if let cellView = registerEditorCellInBundle(bundle,
						nibName: "DDLSubmitButtonTableCell",
						cellId: "SubmitButton") {
					submitButtonHeight = cellView.bounds.size.height

					break
				}
			}
		}
	}

	internal func registerCustomEditor(field: DDLField) -> Bool {
        let bundles = Bundle.allBundles(currentClass: type(of: self));

		for bundle in bundles {
            if let cellView = registerEditorCellInBundle(bundle: bundle,
					nibName: "DDLCustomField\(field.name)TableCell",
					cellId: field.name) {

                setCellHeight(height: cellView.bounds.size.height, forField: field)

				return true
			}
		}

		return false
	}

    internal func registerEditorCellInBundle(bundle: Bundle,
			nibName: String,
			cellId: String)
			-> UITableViewCell? {

		let existingNibName = { (themeName: String) -> String? in
			let themedNibName = "\(nibName)_\(themeName)"

            return bundle.path(forResource: themedNibName, ofType: "nib") != nil
						? themedNibName
						: nil
		}

		let themedNibName = existingNibName(self.themeName)
				?? existingNibName("default")

		if let themedNibNameValue = themedNibName {
			let nib = UINib(nibName: themedNibNameValue, bundle: bundle)

            tableView?.register(nib, forCellReuseIdentifier: cellId)

            let views = nib.instantiate(withOwner: nil, options: nil)

			if let cell = views.first as? UITableViewCell {
				return cell
			}
			else {
				print("ERROR: Cell XIB \(themedNibName) couldn't be registered (no root view?)\n")
			}
		}

		return nil
	}

	internal func cellHeightForField(field: DDLField) -> CGFloat {
		var result: CGFloat = 0.0

		if let cellHeight = cellHeights[field.name] {
			result = cellHeight.current
		}
		else if let typeHeight = cellHeights[field.editorType.toCapitalizedName()] {
			result = typeHeight.current
		}
		else {
			print("ERROR: Height doesn't found for field \(field)\n")
		}

		return result
	}

	internal func setCellHeight(height: CGFloat, forField field: DDLField) {
		if let cellHeight = cellHeights[field.name] {
			cellHeights[field.name] = (cellHeight.registered, height)
		}
		else {
			cellHeights[field.name] = (height, height)
		}
	}

	internal func resetCellHeightForField(field: DDLField) -> CGFloat {
		var result: CGFloat = 0.0

		if let cellHeight = cellHeights[field.name] {
			cellHeights[field.name] = (cellHeight.registered, cellHeight.registered)
			result = cellHeight.registered
		}
		else if let typeHeight = cellHeights[field.editorType.toCapitalizedName()] {
			cellHeights[field.name] = (typeHeight.registered, typeHeight.registered)
			result = typeHeight.registered
		}

		return result
	}

}
