//
//  CropperPresentable.swift
//  ImageCropper
//
//  Created by Mikhail Panfilov on 14.11.2019.
//  Copyright © 2019 Mikhail Panfilov. All rights reserved.
//

import UIKit

protocol ImageCropperPresentable: class { }

extension ImageCropperPresentable where Self: UIViewController {
    func pushImageCropper(from navigationController: UINavigationController, image: UIImage, animated: Bool = true, sourceType: UIImagePickerController.SourceType, completion: @escaping ImageCropperCompletion) {
        let viewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ImageCropperViewController") as! ImageCropperViewController
        viewController.completion = completion
        viewController.originalImage = image
        if sourceType == .camera {
            navigationController.setViewControllers([viewController], animated: animated)
        } else {
            navigationController.pushViewController(viewController, animated: animated)
        }
    }
}
typealias ImageCropperCompletion = ((UIImage) -> ())
