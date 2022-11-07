//
//  OpenCVWrapper.mm
//  OpenCVApp
//
//  Created by Adam Marut on 13/10/2022.
//
#import <opencv2/opencv.hpp>
//#import <opencv2/imgcodecs.hpp>
//#import <opencv2/stiching.hpp>
#import "OpenCVWrapper.h"
#pragma mark - Private Declarations
@interface OpenCVWrapper ()

#ifdef __cplusplus

+ (cv::Mat)_grayFrom:(cv::Mat)source;
+ (cv::Mat)_matFrom:(UIImage *)source;
+ (UIImage *)_imageFrom:(cv::Mat)source;

#endif

@end
using namespace std;
using namespace cv;
#pragma mark - OpenCVWrapper
@implementation OpenCVWrapper
#pragma mark Public
+(UIImage *)toGray:(UIImage *)source{
    std::cout<<"OpenCV: ";
    return [OpenCVWrapper _imageFrom:[OpenCVWrapper _grayFrom:[OpenCVWrapper _matFrom:source]]];
}

+ (NSString *)openCVVersionString {
return [NSString stringWithFormat:@"OpenCV Version %s",  CV_VERSION];
}

+ (UIImage *)stitchPhotos:(NSArray *) photos panoramicWarp:(BOOL) isPanoramic{
    Mat output;
    vector<Mat> frames ;
    
    for(UIImage *image in photos)
    {
        UIImage* rotatedImage = [image rotateToImageOrientation];
        frames.push_back([OpenCVWrapper _matFrom:rotatedImage]);
    }
    
    cv::Ptr<Stitcher> pStitcher = nullptr;
    if (isPanoramic){
        pStitcher= Stitcher::create(Stitcher::PANORAMA);
        pStitcher->setPanoConfidenceThresh(0.5);

        cout<<"Panoramic"<<endl;
    }
    else{
        pStitcher= Stitcher::create(Stitcher::SCANS);
        pStitcher->setPanoConfidenceThresh(0.5);
        cout<<"Scans"<<endl;

    }
    try{
        Stitcher::Status stitcherSuccess = pStitcher->stitch(frames, output);
        if(stitcherSuccess==Stitcher::OK)
        {
            return [OpenCVWrapper _imageFrom:output];
        }
    }
    catch(const std::exception & e)
    {
        cout <<e.what()<<endl;
    }

    cout<< "Can't stitch images: "<<endl;
    return nil;}


+(UIImage *)stitchPhotos:(UIImage *) source1 photo2: (UIImage *) source2 panoramicWarp:(BOOL) isPanoramic;{
    Mat output;
    vector<Mat> frames ;
    
    UIImage* rotatedImage = [source1 rotateToImageOrientation];
      cv::Mat matImage = [OpenCVWrapper _matFrom:rotatedImage];
    UIImage* rotatedImage2 = [source2 rotateToImageOrientation];
      cv::Mat matImage2 = [OpenCVWrapper _matFrom:rotatedImage2];
      frames.push_back(matImage);
    frames.push_back(matImage2);
    cv::Ptr<Stitcher> pStitcher = nullptr;
    if (isPanoramic){
        pStitcher= Stitcher::create(Stitcher::PANORAMA);
        cout<<"Panoramic"<<endl;
    }
    else{
        pStitcher= Stitcher::create(Stitcher::SCANS);
        cout<<"Scans"<<endl;

    }
    try{
        Stitcher::Status stitcherSuccess = pStitcher->stitch(frames, output);
        if(stitcherSuccess==Stitcher::OK)
        {
            return [OpenCVWrapper _imageFrom:output];
        }
    }
    catch(const std::exception & e)
    {
        cout <<e.what()<<endl;
    }

    cout<< "Can't stitch images: "<<endl;
    return nil;
    
}

+(UIImage *)cropStitchedPhoto:(UIImage *) source{
    return [OpenCVWrapper _imageFrom:[OpenCVWrapper _cropStichedImage:[OpenCVWrapper _matFrom:source]]];
}

#pragma mark Private

+ (cv::Mat)_grayFrom:(cv::Mat)source {
    std::cout << "-> grayFrom ->";
    
    cv::Mat result;
    cv::cvtColor(source, result, cv::COLOR_BGR2GRAY);
    
    return result;
}

+ (cv::Mat)_matFrom:(UIImage *)source {
    std::cout << "matFrom ->";
    
    CGImageRef image = CGImageCreateCopy(source.CGImage);
    CGFloat cols = CGImageGetWidth(image);
    CGFloat rows = CGImageGetHeight(image);
    cv::Mat result(rows, cols, CV_8UC4);
    
    CGBitmapInfo bitmapFlags = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = result.step[0];
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
    
    CGContextRef context = CGBitmapContextCreate(result.data, cols, rows, bitsPerComponent, bytesPerRow, colorSpace, bitmapFlags);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, cols, rows), image);
    CGContextRelease(context);
    cvtColor(result,result,COLOR_BGRA2BGR);
    
    
    return result;
}

+ (UIImage *)_imageFrom:(cv::Mat)source {
    std::cout << "-> imageFrom\n";
    cvtColor(source,source,COLOR_BGR2BGRA);

    NSData *data = [NSData dataWithBytes:source.data length:source.elemSize() * source.total()];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

    CGBitmapInfo bitmapFlags = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = source.step[0];
    CGColorSpaceRef colorSpace = (source.elemSize() == 1 ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB());
    
    CGImageRef image = CGImageCreate(source.cols, source.rows, bitsPerComponent, bitsPerComponent * source.elemSize(), bytesPerRow, colorSpace, bitmapFlags, provider, NULL, false, kCGRenderingIntentDefault);
    UIImage *result = [UIImage imageWithCGImage:image];
    
    CGImageRelease(image);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return result;
}

+ (cv::Mat)_cropStichedImage:(cv::Mat)source{
    cv::Mat _gray, _thresh;
    cv::cvtColor(source,_gray,cv::COLOR_BGR2GRAY);
    cv::threshold(_gray, _thresh, 0, 255, cv::THRESH_BINARY);
    
    std::vector<std::vector<cv::Point>> _contours;
    cv::findContours(_thresh, _contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    cv::fillPoly(_thresh, _contours.at([OpenCVWrapper _getMaxAreaContourId:_contours]), cv::Scalar(255,255,255));
    cv::Mat mask = cv::Mat(_thresh.size().height,_thresh.size().width, CV_8U, double(0));
    cv::Rect bbox = cv::boundingRect(_contours.at([OpenCVWrapper _getMaxAreaContourId:_contours]));
    cv::rectangle(mask, cv::Point(bbox.x+10,bbox.y+10),cv::Point(bbox.x-20+bbox.width,bbox.y-20+bbox.height), cv::Scalar(255,255,255),-1);
    cv::Mat minRectangle, sub;
    mask.copyTo(minRectangle);
    mask.copyTo(sub);
    cv::Mat kernel = cv::getStructuringElement( cv::MORPH_RECT,
                                               cv::Size( 9, 9 ));
    while (cv::countNonZero(sub)>0) {
    //for(int i = 0;i<10;i++){
        cv::erode(minRectangle, minRectangle, kernel);
        cv::subtract(minRectangle, _thresh, sub);
        
    }
    
    std::cout<<"Min rect found"<<std::endl;
    cv::findContours(minRectangle, _contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    std::cout<<"Contours found"<<_contours[0]<<std::endl;

    cv::Rect cropRect = cv::boundingRect(_contours.at([OpenCVWrapper _getMaxAreaContourId:_contours]));
    std::cout<<"Image size"<<source.size().width<<"x"<<source.size().height<<std::endl;
    return source(cropRect);
}

+ (int) _getMaxAreaContourId:(std::vector <std::vector<cv::Point>>) contours {
    double maxArea = 0;
    int maxAreaContourId = -1;
    for (int j = 0; j < contours.size(); j++) {
        double newArea = cv::contourArea(contours.at(j));
        if (newArea > maxArea) {
            maxArea = newArea;
            maxAreaContourId = j;
        } // End if
    } // End for
    return maxAreaContourId;
} // End function

+ (BOOL)hasAlpha : (UIImage*) img
{
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(img.CGImage);
    return (
            alpha == kCGImageAlphaFirst ||
            alpha == kCGImageAlphaLast ||
            alpha == kCGImageAlphaPremultipliedFirst ||
            alpha == kCGImageAlphaPremultipliedLast
            );

}
@end
