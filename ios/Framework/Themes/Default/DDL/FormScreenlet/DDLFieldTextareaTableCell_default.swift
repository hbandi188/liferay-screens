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


public class DDLFieldTextareaTableCell_default: DDLFieldTableCell, UITextViewDelegate {

	@IBOutlet public var textView: UITextView?
	@IBOutlet public var placeholder: UILabel?
	@IBOutlet public var textViewBackground: UIImageView?
	@IBOutlet public var label: UILabel?
	@IBOutlet public var separator: UIView?

    private var originalTextViewRect = CGRect.zero
	private var originalBackgroundRect: CGRect?
	private var originalSeparatorY: CGFloat?
	private var originalSeparatorDistance: CGFloat?


	//MARK: DDLFieldTableCell

    override public var canBecomeFirstResponder: Bool {
        return textView?.canBecomeFirstResponder ?? false
	}

	override public func becomeFirstResponder() -> Bool {
		return textView!.becomeFirstResponder()
	}

	override public func onChangedField() {
		if let stringField = field as? DDLFieldString {

			if stringField.currentValue != nil {
				textView?.text = stringField.currentValueAsString
			}

			var currentHeight = self.frame.size.height

			if stringField.showLabel {
				placeholder?.text = ""

				if let labelValue = label {
					labelValue.text = stringField.label
                    labelValue.isHidden = false

                    moveSubviewsVertically(offsetY: 0.0)
				}
			}
			else {
				placeholder?.text = stringField.label
				placeholder?.alpha = (textView?.text == "") ? 1.0 : 0.0

				if let labelValue = label {
                    labelValue.isHidden = true

					moveSubviewsVertically(
                        offsetY: -(DDLFieldTextFieldHeightWithLabel - DDLFieldTextFieldHeightWithoutLabel))

                    setCellHeight(height: DDLFieldTextFieldHeightWithoutLabel)

					currentHeight = DDLFieldTextFieldHeightWithoutLabel
				}
			}

            textView?.returnKeyType = isLastCell ? .send : .next

			originalTextViewRect = textView!.frame
			originalBackgroundRect = textViewBackground?.frame
			if separator != nil {
				originalSeparatorY = separator!.frame.origin.y
				originalSeparatorDistance = currentHeight - originalSeparatorY!
			}

			if stringField.lastValidationResult != nil {
                onPostValidation(valid: stringField.lastValidationResult!)
			}
		}
	}

	override public func onPostValidation(valid: Bool) {
        super.onPostValidation(valid: valid)

        textViewBackground?.image = Bundle.imageInBundles(
					name: valid ? "default-field" : "default-field-failed",
                    currentClass: type(of: self))
	}


	//MARK: UITextViewDelegate

    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
		let heightLabelOffset:CGFloat =
				DDLFieldTextFieldHeightWithLabel - DDLFieldTextFieldHeightWithoutLabel

		let newCellHeight = DDLFieldTextareaExpandedCellHeight +
				(field!.showLabel ? heightLabelOffset : 0.0)

        setCellHeight(height: newCellHeight)

		if let value = originalSeparatorDistance {
			separator?.frame.origin.y = newCellHeight - value
		}

		textView.frame = CGRect(
            x: originalTextViewRect.origin.x,
            y: originalTextViewRect.origin.y,
            width: originalTextViewRect.size.width,
            height: DDLFieldTextareaExpandedTextViewHeight)

		textViewBackground?.frame.size.height = DDLFieldTextareaExpandedBackgroundHeight

        textViewBackground?.isHighlighted = true

		formView!.firstCellResponder = textView

		return true
	}

    public func textViewDidEndEditing(_ textView: UITextView) {
		if let originalSeparatorY = originalSeparatorY {
			separator?.frame.origin.y = originalSeparatorY
		}

		textView.frame = originalTextViewRect

		if let originalBackgroundRect = originalBackgroundRect {
			textViewBackground?.frame = originalBackgroundRect
		}

		let heightLabelOffset: CGFloat =
				DDLFieldTextFieldHeightWithLabel - DDLFieldTextFieldHeightWithoutLabel

		let height = resetCellHeight()

		if !field!.showLabel {
            setCellHeight(height: height - heightLabelOffset)
		}

        textViewBackground?.isHighlighted = false
	}

    public func textView(_ textView: UITextView,
                         shouldChangeTextIn range: NSRange,
			replacementText text: String) -> Bool {

		var result = false

		if text == "\n" {
            textViewDidEndEditing(textView)
            nextCellResponder(currentView: textView)
			result = false
		} else {
			result = true

            let newText = (textView.text as NSString).replacingCharacters(in: range,
                                                                          with:text)

			placeholder!.changeVisibility(visible: newText != "")

            field?.currentValue = newText as AnyObject

			if field!.lastValidationResult != nil && !field!.lastValidationResult! {
				field!.lastValidationResult = true
                onPostValidation(valid: true)
			}
		}

		return result
	}

}
