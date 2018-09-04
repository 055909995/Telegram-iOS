import Foundation
import Postbox
import SwiftSignalKit
import Display
import TelegramUIPrivateModule
import TelegramCore

private func imageFromAJpeg(data: Data) -> (UIImage, UIImage)? {
    if let (colorData, alphaData) = data.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) -> (Data, Data)? in
        var colorSize: Int32 = 0
        memcpy(&colorSize, bytes, 4)
        if colorSize < 0 || Int(colorSize) > data.count - 8 {
            return nil
        }
        var alphaSize: Int32 = 0
        memcpy(&alphaSize, bytes.advanced(by: 4 + Int(colorSize)), 4)
        if alphaSize < 0 || Int(alphaSize) > data.count - Int(colorSize) - 8 {
            return nil
        }
        //let colorData = Data(bytesNoCopy: UnsafeMutablePointer(mutating: bytes).advanced(by: 4), count: Int(colorSize), deallocator: .none)
        //let alphaData = Data(bytesNoCopy: UnsafeMutablePointer(mutating: bytes).advanced(by: 4 + Int(colorSize) + 4), count: Int(alphaSize), deallocator: .none)
        let colorData = data.subdata(in: 4 ..< (4 + Int(colorSize)))
        let alphaData = data.subdata(in: (4 + Int(colorSize) + 4) ..< (4 + Int(colorSize) + 4 + Int(alphaSize)))
        return (colorData, alphaData)
    }) {
        if let colorImage = UIImage(data: colorData), let alphaImage = UIImage(data: alphaData) {
            return (colorImage, alphaImage)
            
            /*return generateImage(CGSize(width: colorImage.size.width * colorImage.scale, height: colorImage.size.height * colorImage.scale), contextGenerator: { size, context in
                colorImage.draw(in: CGRect(origin: CGPoint(), size: size))
            }, scale: 1.0)*/
        }
    }
    return nil
}

private func chatMessageStickerDatas(account: Account, file: TelegramMediaFile, small: Bool, fetched: Bool, onlyFullSize: Bool) -> Signal<(Data?, Data?, Bool), NoError> {
    let maybeFetched = account.postbox.mediaBox.cachedResourceRepresentation(file.resource, representation: CachedStickerAJpegRepresentation(size: small ? CGSize(width: 160.0, height: 160.0) : nil), complete: onlyFullSize)
    
    return maybeFetched |> take(1) |> mapToSignal { maybeData in
        if maybeData.complete {
            let loadedData: Data? = try? Data(contentsOf: URL(fileURLWithPath: maybeData.path), options: [])
            
            return .single((nil, loadedData, true))
        } else {
            let fullSizeData = account.postbox.mediaBox.cachedResourceRepresentation(file.resource, representation: CachedStickerAJpegRepresentation(size: small ? CGSize(width: 160.0, height: 160.0) : nil), complete: false) |> map { next in
                return (next.size == 0 ? nil : try? Data(contentsOf: URL(fileURLWithPath: next.path), options: .mappedIfSafe), next.complete)
            }
            
            if fetched {
                return Signal { subscriber in
                    let fetch = fetchedMediaResource(postbox: account.postbox, reference: stickerPackFileReference(file).resourceReference(file.resource)).start()
                    let disposable = (fullSizeData |> map { (data, complete) -> (Data?, Data?, Bool) in
                        return (nil, data, complete)
                    }).start(next: { next in
                        subscriber.putNext(next)
                    }, error: { error in
                        subscriber.putError(error)
                    }, completed: {
                        subscriber.putCompletion()
                    })
                    
                    return ActionDisposable {
                        fetch.dispose()
                        disposable.dispose()
                    }
                }
            } else {
                return fullSizeData |> map { (data, complete) -> (Data?, Data?, Bool) in
                    return (nil, data, complete)
                }
            }
        }
    }
}

func chatMessageLegacySticker(account: Account, file: TelegramMediaFile, small: Bool, fitSize: CGSize, fetched: Bool = false, onlyFullSize: Bool = false) -> Signal<(TransformImageArguments) -> DrawingContext?, NoError> {
    let signal = chatMessageStickerDatas(account: account, file: file, small: small, fetched: fetched, onlyFullSize: onlyFullSize)
    return signal |> map { (thumbnailData, fullSizeData, fullSizeComplete) in
        return { preArguments in
            var fullSizeImage: (UIImage, UIImage)?
            if let fullSizeData = fullSizeData, fullSizeComplete {
                if let image = imageFromAJpeg(data: fullSizeData) {
                    fullSizeImage = image
                }
            }
            
            if let fullSizeImage = fullSizeImage {
                var updatedFitSize = fitSize
                if updatedFitSize.width.isEqual(to: 1.0) {
                    updatedFitSize = fullSizeImage.0.size
                }
                
                let contextSize = fullSizeImage.0.size.aspectFitted(updatedFitSize)
                
                let arguments = TransformImageArguments(corners: preArguments.corners, imageSize: contextSize, boundingSize: contextSize, intrinsicInsets: preArguments.intrinsicInsets)
                
                let context = DrawingContext(size: arguments.drawingSize, clear: true)
                
                let thumbnailImage: CGImage? = nil
                
                var blurredThumbnailImage: UIImage?
                if let thumbnailImage = thumbnailImage {
                    let thumbnailSize = CGSize(width: thumbnailImage.width, height: thumbnailImage.height)
                    let thumbnailContextSize = thumbnailSize.aspectFitted(CGSize(width: 150.0, height: 150.0))
                    let thumbnailContext = DrawingContext(size: thumbnailContextSize, scale: 1.0)
                    thumbnailContext.withFlippedContext { c in
                        c.interpolationQuality = .none
                        c.draw(thumbnailImage, in: CGRect(origin: CGPoint(), size: thumbnailContextSize))
                    }
                    telegramFastBlur(Int32(thumbnailContextSize.width), Int32(thumbnailContextSize.height), Int32(thumbnailContext.bytesPerRow), thumbnailContext.bytes)
                    
                    blurredThumbnailImage = thumbnailContext.generateImage()
                }
                
                context.withFlippedContext { c in
                    c.setBlendMode(.copy)
                    if let blurredThumbnailImage = blurredThumbnailImage {
                        c.interpolationQuality = .low
                        c.draw(blurredThumbnailImage.cgImage!, in: arguments.drawingRect)
                    }
                    
                    if let cgImage = fullSizeImage.0.cgImage, let cgImageAlpha = fullSizeImage.1.cgImage {
                        c.setBlendMode(.normal)
                        c.interpolationQuality = .medium
                        
                        let mask = CGImage(maskWidth: cgImageAlpha.width, height: cgImageAlpha.height, bitsPerComponent: cgImageAlpha.bitsPerComponent, bitsPerPixel: cgImageAlpha.bitsPerPixel, bytesPerRow: cgImageAlpha.bytesPerRow, provider: cgImageAlpha.dataProvider!, decode: nil, shouldInterpolate: true)
                        
                        c.draw(cgImage.masking(mask!)!, in: arguments.drawingRect)
                    }
                }
                
                return context
            } else {
                return nil
            }
        }
    }
}

func chatMessageSticker(account: Account, file: TelegramMediaFile, small: Bool, fetched: Bool = false, onlyFullSize: Bool = false) -> Signal<(TransformImageArguments) -> DrawingContext?, NoError> {
    let signal = chatMessageStickerDatas(account: account, file: file, small: small, fetched: fetched, onlyFullSize: onlyFullSize)
    
    return signal |> map { (thumbnailData, fullSizeData, fullSizeComplete) in
        return { arguments in
            let context = DrawingContext(size: arguments.drawingSize, clear: true)
            
            let drawingRect = arguments.drawingRect
            let fittedSize = arguments.imageSize
            let fittedRect = CGRect(origin: CGPoint(x: drawingRect.origin.x + (drawingRect.size.width - fittedSize.width) / 2.0, y: drawingRect.origin.y + (drawingRect.size.height - fittedSize.height) / 2.0), size: fittedSize)
            //let fittedRect = arguments.drawingRect
            
            var fullSizeImage: (UIImage, UIImage)?
            if let fullSizeData = fullSizeData, fullSizeComplete {
                if let image = imageFromAJpeg(data: fullSizeData) {
                    fullSizeImage = image
                }
            }
            
            let thumbnailImage: CGImage? = nil
            
            var blurredThumbnailImage: UIImage?
            if let thumbnailImage = thumbnailImage {
                let thumbnailSize = CGSize(width: thumbnailImage.width, height: thumbnailImage.height)
                let thumbnailContextSize = thumbnailSize.aspectFitted(CGSize(width: 150.0, height: 150.0))
                let thumbnailContext = DrawingContext(size: thumbnailContextSize, scale: 1.0)
                thumbnailContext.withFlippedContext { c in
                    c.interpolationQuality = .none
                    c.draw(thumbnailImage, in: CGRect(origin: CGPoint(), size: thumbnailContextSize))
                }
                telegramFastBlur(Int32(thumbnailContextSize.width), Int32(thumbnailContextSize.height), Int32(thumbnailContext.bytesPerRow), thumbnailContext.bytes)
                
                blurredThumbnailImage = thumbnailContext.generateImage()
            }
            
            context.withFlippedContext { c in
                c.setBlendMode(.copy)
                if let blurredThumbnailImage = blurredThumbnailImage {
                    c.interpolationQuality = .low
                    c.draw(blurredThumbnailImage.cgImage!, in: fittedRect)
                }
                
                if let fullSizeImage = fullSizeImage, let cgImage = fullSizeImage.0.cgImage, let cgImageAlpha = fullSizeImage.1.cgImage {
                    c.setBlendMode(.normal)
                    c.interpolationQuality = .medium
                    
                    let mask = CGImage(maskWidth: cgImageAlpha.width, height: cgImageAlpha.height, bitsPerComponent: cgImageAlpha.bitsPerComponent, bitsPerPixel: cgImageAlpha.bitsPerPixel, bytesPerRow: cgImageAlpha.bytesPerRow, provider: cgImageAlpha.dataProvider!, decode: nil, shouldInterpolate: true)
                    
                    c.draw(cgImage.masking(mask!)!, in: fittedRect)
                }
            }
            
            return context
        }
    }
}
