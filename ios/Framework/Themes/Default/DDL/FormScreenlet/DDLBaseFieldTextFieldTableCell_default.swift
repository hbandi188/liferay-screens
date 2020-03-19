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


public class DDLBaseFieldTextboxTableCell_default: DDLFieldTableCell, UITextFieldDelegate {

	@IBOutlet public var textField: UITextField?
	@IBOutlet public var textFieldBackground: UIImageView?
	@IBOutlet public var label: UILabel?


	//MARK: DDLFieldTableCell

	override public func onChangedField() {
		if field!.showLabel {
			textField?.placeholder = ""

			if let labelValue = label {
				labelValue.text = field!.label
                labelValue.isHidden = false

                moveSubviewsVertically(offsetY: 0.0)
			}
		}
		else {
			textField?.placeholder = field!.label

			if let labelValue = label {
                labelValue.isHidden = true

				moveSubviewsVertically(
                    offsetY: -(DDLFieldTextFieldHeightWithLabel - DDLFieldTextFieldHeightWithoutLabel))

                setCellHeight(height: DDLFieldTextFieldHeightWithoutLabel)
			}
		}

        textField?.returnKeyType = isLastCell ? .send : .next

		if field!.lastValidationResult != nil {
            onPostValidation(valid: field!.lastValidationResult!)
		}

		if field!.currentValue != nil {
			textField?.text = field!.currentValueAsString
		}
	}

	override public func onPostValidation(valid: Bool) {
        super.onPostValidation(valid: valid)

		if valid {
            textFieldBackground?.image = Bundle.imageInBundles(
					name: "default-field",
                    currentClass: type(of: self))

            textFieldBackground?.highlightedImage = Bundle.imageInBundles(
					name: "default-field-focused",
                    currentClass: type(of: self))
		}
		else {
            let image = Bundle.imageInBundles(
					name: "default-field-failed",
                    currentClass: type(of: self))

			textFieldBackground?.image = image
			textFieldBackground?.highlightedImage = image
		}
	}

    override public var canBecomeFirstResponder: Bool {
        return self.textField?.canBecomeFirstResponder ?? false
    }

	override public func becomeFirstResponder() -> Bool {
        return self.textField?.becomeFirstResponder() ?? false
	}


	//MARK: UITextFieldDelegate

    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textFieldBackground?.isHighlighted = true

		formView!.firstCellResponder = textField

		return true
	}

    public func textFieldDidEndEditing(_ textField: UITextField) {
        textFieldBackground?.isHighlighted = false
	}

    public func textField(_ textField: UITextField,
                          shouldChangeCharactersIn range: NSRange,
			replacementString string: String) -> Bool {

		if field!.lastValidationResult != nil && !field!.lastValidationResult! {
			field!.lastValidationResult = true
            onPostValidation(valid: true)

			//FIXME!
			// This hack is the only way I found to repaint the text field while it's in
			// edition mode. It doesn't produce flickering nor nasty effects.

            textFieldBackground?.isHighlighted = false
            textFieldBackground?.isHighlighted = true
		}

		return true
	}

}
