//
//  ImageCropperViewController.swift
//  ImageCropper
//
//  Created by Mikhail Panfilov on 14.11.2019.
//  Copyright © 2019 Mikhail Panfilov. All rights reserved.
//

import UIKit
import AVFoundation

class ImageCropperViewController: UIViewController {
    
    // MARK: Constants

    let zoomScale: CGFloat = 1.0
    let minimumZoomScale: CGFloat = 1.0
    let maximumZoomScale: CGFloat = 10.0
    let resizeImageWidth = 3024
    let resizeImageHeight = 4032
    let cropAreaCornerRadius: CGFloat = 0
    
    // MARK: IBOutlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var buttonsContainerView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    
    // MARK: Properties
    
    var completion: ImageCropperCompletion?
    var originalImage: UIImage!
    var sourceType: UIImagePickerController.SourceType?
    
    private let borderWidth: CGFloat = 0.5
    private var circlePath = UIBezierPath()
    private var isViewConfigured = false
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isViewConfigured {
            isViewConfigured = true
            DispatchQueue.main.async {
                let centerOffsetX = (self.scrollView.contentSize.width - self.scrollView.frame.size.width) / 2
                let centerOffsetY = (self.scrollView.contentSize.height - self.scrollView.frame.size.height) / 2
                let centerPoint = CGPoint(x: centerOffsetX, y: centerOffsetY)
                self.scrollView.setContentOffset(centerPoint, animated: false)
            }
        }
    }
    
    // MARK: Private methods
    
    private func configure() {
        let squareSize: CGFloat = view.frame.width
        let width = view.frame.size.width
        let height = view.frame.size.height
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.maximumZoomScale = maximumZoomScale
        scrollView.zoomScale = zoomScale
        
        imageView.contentMode = .scaleAspectFit
        imageView.image = originalImage.resize(to: CGSize(width: resizeImageWidth, height: resizeImageHeight))
        
        let aspectFitImageFrame: CGRect = AVMakeRect(aspectRatio: imageView.image!.size, insideRect: view.frame)
        imageHeightConstraint.constant = aspectFitImageFrame.height
        if aspectFitImageFrame.height < width {
            DispatchQueue.main.async {
                let zoomScale = width / aspectFitImageFrame.height
                self.scrollView.minimumZoomScale = zoomScale
                self.scrollView.setZoomScale(zoomScale, animated: false)
            }
        }
        
        configureCrop(layer: CGRect(x: (width / 2) - squareSize / 2, y: (height / 2) - (squareSize / 2), width: squareSize, height: squareSize), cornerRadius: cropAreaCornerRadius)
        view.bringSubviewToFront(buttonsContainerView)
    }

    private func configureCrop(layer: CGRect, cornerRadius: CGFloat) {
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height), cornerRadius: 0)
        circlePath = UIBezierPath(roundedRect: layer, cornerRadius: cornerRadius)
        path.append(circlePath)
        path.usesEvenOddFillRule = true
        let fillLayer = CAShapeLayer()
        fillLayer.path = path.cgPath
        fillLayer.borderWidth = 3
        fillLayer.borderColor = UIColor.red.cgColor
        fillLayer.fillRule = CAShapeLayerFillRule.evenOdd
        fillLayer.opacity = 0.5
        fillLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        view.layer.addSublayer(fillLayer)
        
        let borderPath = UIBezierPath(roundedRect: CGRect(x: layer.minX + borderWidth, y: layer.minY + borderWidth, width: layer.width - (borderWidth * 2), height: layer.height - (borderWidth * 2)), cornerRadius: cornerRadius)
        let borderLayer = CAShapeLayer()
        borderLayer.path = borderPath.cgPath
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.lineWidth = borderWidth
        view.layer.addSublayer(borderLayer)
    }
    
    private func getCropArea() -> CGRect {
        let factor = imageView.image!.size.width/view.frame.width
        let scale = 1/scrollView.zoomScale
        let imageFrame = imageView.imageFrame
        let x = (scrollView.contentOffset.x + circlePath.bounds.origin.x - imageFrame.origin.x) * scale * factor
        let y = (scrollView.contentOffset.y - imageFrame.origin.y) * scale * factor
        let width =  circlePath.bounds.width  * scale * factor
        let height = circlePath.bounds.height  * scale * factor
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    // MARK: IBActions
    
    @IBAction private func cancelTouchUpInside(_ sender: UIButton) {
        guard let navigationController = navigationController, let sourceType = sourceType else {
            dismiss(animated: true)
            return
        }
        if sourceType == .photoLibrary {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @IBAction private func cropTouchUpInside(_ sender: UIButton) {
        guard !scrollView.isDragging else { return }
        let croppedCGImage = imageView.image?.cgImage?.cropping(to: getCropArea())
        let croppedImage = UIImage(cgImage: croppedCGImage!)
        completion?(croppedImage)
    }
}

//MARK: UIScrollViewDelegate

extension ImageCropperViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}

//MARK: UIImageView extension

fileprivate extension UIImageView {
    var imageFrame: CGRect {
        let imageViewSize = self.frame.size
        guard let imageSize = self.image?.size else {
            return CGRect.zero
        }
        
        // Figure out the orientation is using
        let imageRatio = imageSize.width / imageSize.height
        let imageViewRatio = imageViewSize.width / imageViewSize.height
        if imageRatio < imageViewRatio {
            let scaleFactor = imageViewSize.height / imageSize.height
            let width = imageSize.width * scaleFactor
            let topLeftX = (imageViewSize.width - width) * 0.5
            return CGRect(x: topLeftX, y: 0, width: width, height: imageViewSize.height)
        } else {
            let scaleFactor = imageViewSize.width / imageSize.width
            let height = imageSize.height * scaleFactor
            let topLeftY = (imageViewSize.height - height) * 0.5
            return CGRect(x: 0, y: topLeftY, width: imageViewSize.width, height: height)
        }
    }
}

//MARK: UIImage extension

fileprivate extension UIImage {
    func resize(to targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / self.size.width
        let heightRatio = targetSize.height / self.size.height
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

