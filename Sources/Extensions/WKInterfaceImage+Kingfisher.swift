//
//  WKInterfaceImage+Kingfisher.swift
//  Kingfisher
//
//  Created by Rodrigo Borges Soares on 04/05/18.
//
//  Copyright (c) 2018 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import WatchKit

// MARK: - Extension methods.
/**
 *    Set image to use from web.
 */
extension KingfisherClass where Base: WKInterfaceImage {
    /**
     Set an image with a resource.

     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     - parameter options:           A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called when the image downloading progress gets updated.
     - parameter completionHandler: Called when the image retrieved and set.

     - returns: A task represents the retrieving process.
     */
    @discardableResult
    public func setImage(with resource: Resource?,
                         placeholder: Image? = nil,
                         options: KingfisherOptionsInfo? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: ((Result<RetrieveImageResult>) -> Void)? = nil) -> DownloadTask?
    {
        guard let resource = resource else {
            base.setImage(placeholder)
            webURL = nil
            completionHandler?(.failure(KingfisherError2.imageSettingError(reason: .emptyResource)))
            return nil
        }

        let options = KingfisherManager.shared.defaultOptions + (options ?? .empty)
        if !options.keepCurrentImageWhileLoading {
            base.setImage(placeholder)
        }

        webURL = resource.downloadURL
        let task = KingfisherManager.shared.retrieveImage(
            with: resource,
            options: options,
            progressBlock: { receivedSize, totalSize in
                guard resource.downloadURL == self.webURL else { return }
                progressBlock?(receivedSize, totalSize)
            },
            completionHandler: { result in
                DispatchQueue.main.safeAsync {
                    guard resource.downloadURL == self.webURL else {
                        let error = KingfisherError2.imageSettingError(
                            reason: .notCurrentResource(result: result, resource: resource))
                        completionHandler?(.failure(error))
                        return
                    }

                    self.imageTask = nil

                    switch result {
                    case .success(let value):
                        self.base.setImage(value.image)
                        completionHandler?(result)
                    case .failure:
                        completionHandler?(result)
                    }
                }
            })

        imageTask = task
        return task
    }

    /**
     Cancel the image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    public func cancelDownloadTask() {
        imageTask?.cancel()
    }
}

// MARK: - Associated Object
private var lastURLKey: Void?
private var imageTaskKey: Void?

extension KingfisherClass where Base: WKInterfaceImage {
    /// Get the image URL bound to this image view.
    public private(set) var webURL: URL? {
        get { return getAssociatedObject(base, &lastURLKey) }
        set { setRetainedAssociatedObject(base, &lastURLKey, newValue) }
    }

    private var imageTask: DownloadTask? {
        get { return getAssociatedObject(base, &imageTaskKey) }
        set { setRetainedAssociatedObject(base, &imageTaskKey, newValue)}
    }
}

