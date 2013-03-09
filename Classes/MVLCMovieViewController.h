//
//  MVLCMovieViewController.h
//  MobileVLC
//
//  Created by Romain Goyet on 06/07/10.
//  Copyright 2010 Applidium. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileVLCKit/MobileVLCKit.h>

@class MLFile;

@interface MVLCMovieViewController : UIViewController <VLCMediaPlayerDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
    MLFile *         _file;
    NSURL *          _url; // Either one file *or* one url should be specified

    VLCMediaPlayer * _mediaPlayer;
    UIView *         _movieView;
    UIView *         _HUDView;
    UIView *         _topView;
    UIBarItem *_remainingTimeLabel;
    UISlider *       _positionSlider;
    UISlider *       _volumeSlider;
    UIButton *       _playOrPauseButton;
    UIButton *       _trackSelectorButton;
    UIBarButtonItem * _doneBarButton;
    BOOL             _hudVisibility;
    BOOL             _wasPushedAnimated;
    UINavigationController * _navigationController;
}
@property (nonatomic, retain) MLFile * file;
@property (nonatomic, retain) NSURL * url;
@property (nonatomic, retain) IBOutlet UIView * movieView;
@property (nonatomic, retain) IBOutlet UIView * HUDView;
@property (nonatomic, retain) IBOutlet UIView * topView;
@property (nonatomic, retain) IBOutlet UIBarItem * remainingTimeLabel;
@property (nonatomic, retain) IBOutlet UISlider * positionSlider;
@property (nonatomic, retain) IBOutlet UISlider * volumeSlider;
@property (nonatomic, retain) IBOutlet UIButton * playOrPauseButton;
@property (nonatomic, retain) IBOutlet UIButton * trackSelectorButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem * doneBarButton;
@property (nonatomic, assign) BOOL hudVisibility;

@property (nonatomic, retain) IBOutlet UIView *playingExternallyView;
@property (nonatomic, retain) IBOutlet UILabel *titleTvLabel;
@property (nonatomic, retain) IBOutlet UILabel *descriptionTvLabel;

- (IBAction)toggleHUDVisibility:(id)sender;
- (IBAction)togglePlayOrPause:(id)sender;
- (IBAction)position:(id)sender;
- (IBAction)volume:(id)sender;
- (IBAction)goForward:(id)sender;
- (IBAction)goBackward:(id)sender;
- (IBAction)dismiss:(id)sender;
- (IBAction)switchTrack:(id)sender;
@end
