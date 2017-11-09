//
//  LennySiriManagerOC.m
//  Voice Translator
//
//  Created by 刘爽 on 2017/11/1.
//  Copyright © 2017年 Unknow. All rights reserved.
//

#import "LennySiriManagerOC.h"
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>

@interface LennySiriManagerOC() <SFSpeechRecognizerDelegate>

@property (nonatomic, strong) SFSpeechRecognizer *speechRecoginer;
@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) SFSpeechRecognitionTask *recognitionTask;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;

@end

@implementation LennySiriManagerOC {
    
    SFSpeechRecognitionResult *string_;
    NSTimer *timer_;
    int intCountIncrease;
    BOOL transmit;
    
}

+ (LennySiriManagerOC *)sharedInstance {
    static LennySiriManagerOC *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LennySiriManagerOC alloc] init];
    });
    return instance;
}

- (void)requestAuthorization {
    [SFSpeechRecognizer  requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
//                case SFSpeechRecognizerAuthorizationStatusNotDetermined:
////                    weakSelf.recordButton.enabled = NO;
////                    [weakSelf.recordButton setTitle:@"语音识别未授权" forState:UIControlStateDisabled];
//                    break;
//                case SFSpeechRecognizerAuthorizationStatusDenied:
////                    weakSelf.recordButton.enabled = NO;
////                    [weakSelf.recordButton setTitle:@"用户未授权使用语音识别" forState:UIControlStateDisabled];
//                    break;
//                case SFSpeechRecognizerAuthorizationStatusRestricted:
////                    weakSelf.recordButton.enabled = NO;
////                    [weakSelf.recordButton setTitle:@"语音识别在这台设备上受到限制" forState:UIControlStateDisabled];
//
//                    break;
                case SFSpeechRecognizerAuthorizationStatusAuthorized:
//                    weakSelf.recordButton.enabled = YES;
//                    [weakSelf.recordButton setTitle:@"开始录音" forState:UIControlStateNormal];
                    
                    break;
                default:
                    if ([self.delegate respondsToSelector:@selector(LennySiriManagerOCDidUnAuthorized)]) {
                        [self.delegate LennySiriManagerOCDidUnAuthorized];
                    }
                    break;
            }
            
        });
    }];
}

- (void)startRecording {
    NSLog(@"%s",__func__);
    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    NSParameterAssert(!error);
    [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
    NSParameterAssert(!error);
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    NSParameterAssert(!error);
    
    _recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    NSAssert(inputNode, @"录入设备没有准备好");
    NSAssert(_recognitionRequest, @"请求初始化失败");
    _recognitionRequest.shouldReportPartialResults = YES;
    __weak typeof(self) weakSelf = self;
    _recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:_recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        BOOL isFinal = NO;
        if (result) {
//            strongSelf.resultStringLable.text = result.bestTranscription.formattedString;
            isFinal = result.isFinal;
            NSLog(@"%@", result.bestTranscription.formattedString);
            if (result.bestTranscription.formattedString.length > string_.bestTranscription.formattedString.length) {
                transmit = YES;
                intCountIncrease = 0;
                if ([self.delegate respondsToSelector:@selector(LennySiriManagerOCIsRecognizing)]) {
                    [self.delegate LennySiriManagerOCIsRecognizing];
                }
            } else {
                
            }
//                if ([self.delegate respondsToSelector:@selector(LennySiriManagerOCDidRecognized:)]) {
//                    [self.delegate LennySiriManagerOCDidRecognized:result];
//                }
            
            string_ = result;
        }
//        if (error || isFinal) {
//            [self.audioEngine stop];
//            [inputNode removeTapOnBus:0];
//            strongSelf.recognitionTask = nil;
//            strongSelf.recognitionRequest = nil;
//        }
        
    }];
    
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    //在添加tap之前先移除上一个  不然有可能报"Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio',"之类的错误
    [inputNode removeTapOnBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.recognitionRequest) {
            [strongSelf.recognitionRequest appendAudioPCMBuffer:buffer];
        }
    }];
    
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];
    NSParameterAssert(!error);
//    self.resultStringLable.text = @"正在录音。。。";
    timer_ = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerSelector) userInfo:nil repeats:YES];
    intCountIncrease = 0;
    transmit = NO;
    string_ = [[SFSpeechRecognitionResult alloc] init];
}

- (void)timerSelector {
//    NSLog(@"%s", __func__);
    intCountIncrease++;
    if (transmit) {
        
        if (intCountIncrease > 30) {
            transmit = NO;
            if ([self.delegate respondsToSelector:@selector(LennySiriManagerOCDidRecognized:)]) {
                [self.delegate LennySiriManagerOCDidRecognized:string_];
            }
        }
    }
}

#pragma mark - lazyload
- (AVAudioEngine *)audioEngine{
    if (!_audioEngine) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return _audioEngine;
}

- (void)setRecognizerLanguage:(NSString *)locale {
    NSLog(@"%s",__func__);
    NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:locale];
    
    _speechRecoginer =[[SFSpeechRecognizer alloc] initWithLocale:local];
    _speechRecoginer.delegate = self;
}

- (void)stopRecording {
    NSLog(@"%s",__func__);
    
    [self.audioEngine stop];
    if (_recognitionRequest) {
        [_recognitionRequest endAudio];
    }
    [self.audioEngine.inputNode removeTapOnBus:0];
    _recognitionTask = nil;
    _recognitionRequest = nil;
    
    [timer_ invalidate];
    timer_ = nil;
}

- (void)resetAudioEngine {
    if (self.audioEngine) {
        [self.audioEngine reset];
        [self audioEngine ];
    }
}

- (void)didAudioIsRecording {
    NSLog(@"%s", __func__);
}


- (SFSpeechRecognizer *)speechRecognizer{
    if (!_speechRecoginer) {
        //腰围语音识别对象设置语言，这里设置的是中文
        NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        
        _speechRecoginer =[[SFSpeechRecognizer alloc] initWithLocale:local];
        _speechRecoginer.delegate = self;
    }
    return _speechRecoginer;
}
#pragma mark - SFSpeechRecognizerDelegate
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available{
    NSLog(@"%s",__func__);
    if (available) {
//        self.recordButton.enabled = YES;
//        [self.recordButton setTitle:@"开始录音" forState:UIControlStateNormal];
    }
    else{
//        self.recordButton.enabled = NO;
//        [self.recordButton setTitle:@"语音识别不可用" forState:UIControlStateDisabled];
    }
}
@end
