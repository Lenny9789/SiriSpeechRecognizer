//
//  LennySiriManagerOC.h
//  Voice Translator
//
//  Created by 刘爽 on 2017/11/1.
//  Copyright © 2017年 Unknow. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SFSpeechRecognitionResult;
@protocol LennySiriManagerOCDelegate <NSObject>

- (void)LennySiriManagerOCDidRecognized:(SFSpeechRecognitionResult *)result;

- (void)LennySiriManagerOCDidUnAuthorized;

- (void)LennySiriManagerOCIsRecognizing;

@end

@interface LennySiriManagerOC : NSObject

+ (LennySiriManagerOC *)sharedInstance;

@property (nonatomic, weak) id <LennySiriManagerOCDelegate> delegate;
- (void)requestAuthorization;
- (void)setRecognizerLanguage:(NSString *)locale;
- (void)startRecording;
- (void)stopRecording;
- (void)resetAudioEngine;
@end

