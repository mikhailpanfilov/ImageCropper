//
//  ProfileViewController.swift
//  ImageCropper
//
//  Created by Mikhail Panfilov on 10.02.2020.
//  Copyright © 2020 Mikhail Panfilov. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: Properties
    
    private let imagePicker =  UIImagePickerController()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    // MARK: Private methods
    
    private func configure() {
        imageContainerView.layer.cornerRadius = 50
        imageContainerView.layer.borderWidth = 1
        imageContainerView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.8).cgColor
        imageContainerView.clipsToBounds = true
        imagePicker.delegate = self
    }
    
    // MARK: Selectors
    
    @IBAction private func cameraTouchUpInside(_ sender: UIButton) {
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true)
    }
    
    @IBAction private func photoLibraryTouchUpInside(_ sender: UIButton) {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
}

// MARK: UIImagePickerController Delegate

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[.originalImage] as? UIImage else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        pushImageCropper(from: picker, image: image, sourceType: picker.sourceType) { [unowned self] croppedImage in
            picker.dismiss(animated: true, completion: nil)
            self.imageView.image = croppedImage
        }
    }
}

// MARK: ImageCropperPresentable

extension ProfileViewController: ImageCropperPresentable { }
