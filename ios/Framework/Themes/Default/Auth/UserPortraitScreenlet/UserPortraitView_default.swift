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
	import AFNetworking
#endif


// Global initial load
private func loadPlaceholderCache(done: ((UIImage?) -> ())? = nil) -> UIImage? {
	var image: UIImage?

	dispatch_async {
        image = Bundle.imageInBundles(
			name: "default-portrait-placeholder",
			currentClass: UserPortraitView_default.self)

		UserPortraitView_default.defaultPlaceholder = image

		dispatch_main() {
			done?(image)
		}
	}

	// returns nil because the loading is asynchronous
	return nil
}


public class UserPortraitView_default: BaseScreenletView,
	UserPortraitViewModel,
	UIActionSheetDelegate,
	UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	public static var defaultPlaceholder: UIImage? = loadPlaceholderCache()

	@IBOutlet weak public var activityIndicator: UIActivityIndicatorView?
	@IBOutlet weak public var portraitImage: UIImageView?
	@IBOutlet weak var editButton: UIButton!

	public var borderWidth: CGFloat = 1.0 {
		didSet {
			portraitImage?.layer.borderWidth = borderWidth
		}
	}
	public var borderColor: UIColor? {
		didSet {
            portraitImage?.layer.borderColor = (borderColor ?? DefaultThemeBasicBlue).cgColor
		}
	}
	override public var editable: Bool {
		didSet {
            self.editButton.isHidden = !editable
			if editable {
				self.superview?.clipsToBounds = false
			}
		}
	}

	public var image: UIImage? {
		get {
			return portraitImage?.image
		}
		set {
			if let image = newValue {
				portraitImage?.image = image
			}
			else {
				loadPlaceholder()
			}
		}
	}

	override public var progressMessages: [String:ProgressMessages] {
		return [
			"load-portrait" : [
				.Working : ""
			],
			"upload-portrait" : [
				.Working : "",
                .Failure : LocalizedString(tableName: "default", key: "userportrait-uploading-error", obj: self)
			]]
	}

	private let imagePicker = UIImagePickerController()


	//MARK: BaseScreenletView

	override public func createProgressPresenter() -> ProgressPresenter {
		return UserPortraitDefaultProgressPresenter(spinner: activityIndicator!)
	}

	override public func onCreated() {
		super.onCreated()

		imagePicker.delegate = self
		imagePicker.allowsEditing = true
        imagePicker.modalPresentationStyle = .fullScreen
	}

	override public func onShow() {
		portraitImage?.layer.borderWidth = borderWidth
        portraitImage?.layer.borderColor = (borderColor ?? DefaultThemeBasicBlue).cgColor
		portraitImage?.layer.cornerRadius = DefaultThemeButtonCornerRadius
	}

    override public func onPreAction(name: String, sender: AnyObject?) -> Bool {
		if name == "edit-portrait" {
            let takeNewPicture = LocalizedString(tableName: "default", key: "userportrait-take-new-picture", obj: self)
            let chooseExisting = LocalizedString(tableName: "default", key: "userportrait-choose-existing-picture", obj: self)

			let sheet = UIActionSheet(
				title: "Change portrait",
				delegate: self,
				cancelButtonTitle: "Cancel",
				destructiveButtonTitle: nil, otherButtonTitles: takeNewPicture, chooseExisting)
            sheet.show(in: self)

			return false
		}

		return true
	}

	public func actionSheet(
        _ actionSheet: UIActionSheet,
        clickedButtonAt buttonIndex: Int) {

		let newPicture = 1
		let chooseExisting = 2

		switch buttonIndex {
		case newPicture:
            imagePicker.sourceType = .camera

		case chooseExisting:
            imagePicker.sourceType = .savedPhotosAlbum

		default:
			return
		}

		if let vc = self.presentingViewController {
            vc.present(imagePicker, animated: true, completion: {})
		}
		else {
			print("ERROR: You neet to set the presentingViewController before using UIActionSheet\n")
		}
	}

	public func loadPlaceholder() {
		dispatch_main() {
			if let placeholder = UserPortraitView_default.defaultPlaceholder {
				self.portraitImage?.image = placeholder
			}
			else {
				loadPlaceholderCache {
					self.portraitImage?.image = $0
				}
			}
		}
	}


	//MARK: UIImagePickerControllerDelegate
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage

        imagePicker.dismiss(animated: true) {}

        userAction(name: "upload-portrait", sender: editedImage)
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePicker.dismiss(animated: true) {}
	}

}
