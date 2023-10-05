//
//  ViewController.m
//  gridmind
//
//  Created by Milan Kazarka on 8/8/17.
//  Copyright © 2017 Milan Kazarka. All rights reserved.
//

#import "ViewController.h"
#import <AudioToolbox/AudioServices.h>
#include <math.h>
#include <stdlib.h>
//@import GoogleMobileAds;

@interface ViewController () <UIAlertViewDelegate> {
    SystemSoundID audioEffect;
    SystemSoundID smallwinEffect;
    SystemSoundID winEffect;
    SystemSoundID loseEffect;
}

@property (strong,nonatomic) UILabel *scorelabel;
@property (strong,nonatomic) UIView *gridSquare;
@property (strong,nonatomic) NSMutableArray *cards;
@property (strong,nonatomic) NSMutableArray *buttons;
@property (strong,nonatomic) UIView *progressbar;
@property (strong,nonatomic) UILabel *highscorelabel;
@property (strong,nonatomic) NSNumber *highscore;
@property (strong,nonatomic) NSMutableArray *currentset;
@property (strong,nonatomic) NSMutableArray *selectedset;
@property (strong,nonatomic) UIButton *playButton;

//@property (nonatomic, strong) GADBannerView *bannerView;

@end

@implementation ViewController

-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.97f alpha:1.0f];
    
    //Retrieve audio file
    NSString *path  = [[NSBundle mainBundle] pathForResource:@"click" ofType:@"wav"];
    NSURL *pathURL = [NSURL fileURLWithPath : path];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &audioEffect);
    
    path  = [[NSBundle mainBundle] pathForResource:@"win 2" ofType:@"wav"];
    pathURL = [NSURL fileURLWithPath : path];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &winEffect);
    path  = [[NSBundle mainBundle] pathForResource:@"minimalist win" ofType:@"wav"];
    pathURL = [NSURL fileURLWithPath : path];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &smallwinEffect);
    path  = [[NSBundle mainBundle] pathForResource:@"lose 2" ofType:@"wav"];
    pathURL = [NSURL fileURLWithPath : path];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &loseEffect);
    
    self.highscore = [[NSUserDefaults standardUserDefaults] objectForKey:@"highscore"];
    if (!self.highscore) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:@"highscore"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.highscore = [NSNumber numberWithInt:0];
    }
    
    CGFloat offset = 3.0f;
    self.cards = nil;
    self.buttons = nil;
    self.gridSquare = [[UIView alloc] initWithFrame:CGRectMake(offset,(self.view.frame.size.height/2.0f)-((self.view.frame.size.width-(offset*2.0f))/2.0f)-30.0f,self.view.frame.size.width-(offset*2.0f),self.view.frame.size.width-(offset*2.0f))];
    [self.view addSubview:self.gridSquare];
    self.scorelabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f,0.0f,self.view.frame.size.width/2.0f,self.gridSquare.frame.origin.y)];
    self.scorelabel.text = @"0";
    self.scorelabel.textAlignment = NSTextAlignmentCenter;
    self.scorelabel.font = [self.scorelabel.font fontWithSize:64];
    [self.view addSubview:self.scorelabel];
    self.progressbar = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/3.0f,self.gridSquare.frame.origin.y+self.gridSquare.frame.size.height+30.0f,self.view.frame.size.width/3.0f,10.0f)];
    self.progressbar.layer.cornerRadius = 4.0f;
    self.progressbar.alpha = 0.5f;
    self.progressbar.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.progressbar];
    self.highscorelabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2.0f,0.0f,self.view.frame.size.width/2.0f,self.gridSquare.frame.origin.y)];
    self.highscorelabel.text = [NSString stringWithFormat:@"%@\nhigh",self.highscore];
    self.highscorelabel.numberOfLines = 2;
    self.highscorelabel.textAlignment = NSTextAlignmentCenter;
    self.highscorelabel.font = [self.highscorelabel.font fontWithSize:18];
    [self.view addSubview:self.highscorelabel];
    
    offset = 10.0f;
    self.playButton = [[UIButton alloc] initWithFrame:CGRectMake(offset,self.progressbar.frame.origin.y-10.0f,self.view.frame.size.width-(2.0f*offset),60.0f)];
    [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    self.playButton.layer.cornerRadius = 30.0f;
    self.playButton.backgroundColor = [UIColor redColor];
    self.playButton.alpha = 0.5f;
    [self.playButton addTarget:self
               action:@selector(greatRun)
     forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playButton];
    
    self.currentset = [[NSMutableArray alloc] init];
    self.selectedset = [[NSMutableArray alloc] init];
    
    //self.bannerView = [[GADBannerView alloc]
    //                   initWithAdSize:kGADAdSizeBanner];
    //[self.view addSubview:self.bannerView];
    // test - ca-app-pub-3940256099942544/2934735716
    // real - ca-app-pub-1287256188419142/3344189500
    //self.bannerView.adUnitID = @"ca-app-pub-1287256188419142/3344189500";
    //self.bannerView.rootViewController = self;
    //CGRect frame = self.bannerView.frame;
    //frame.origin.y = self.view.frame.size.height-self.bannerView.frame.size.height;
    //self.bannerView.frame = frame;
    //[self.bannerView loadRequest:[GADRequest request]];
    
    [self greatRun];
}

-(void)greatRun {
    int startdelay = 2000000;
    
    self.playButton.hidden = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int sqr = 3;
        int run = 0;
        int __block level = 1;
        BOOL __block countdown = NO;
        while(1) {
            countdown = NO;
            useconds_t delay = 250000;
            if (startdelay-(run*15000)>delay)
                delay = startdelay-(run*15000);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setCardsNumber:sqr*sqr];
                self.progressbar.frame = CGRectMake(self.view.frame.size.width/3.0f,self.gridSquare.frame.origin.y+self.gridSquare.frame.size.height+30.0f,self.view.frame.size.width/3.0f,10.0f);
                self.scorelabel.text = [NSString stringWithFormat:@"%d",run];
                int __block lastRandom = -1;
                UIColor __block *lastColor = nil;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self.currentset removeAllObjects];
                    [self.selectedset removeAllObjects];
                    if (500000-(run*5000)>150000)
                        usleep(500000-(run*5000));
                    else
                        usleep(150000);
                    for(int n = 0; n < 3; n++) {
                        int randomNumber = 0;
                        while(1) {
                            randomNumber = 0 + rand() % ((int)([self.cards count]-1)-0);
                            if (randomNumber!=lastRandom)
                                break;
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIView *cardview = nil;
                            UIButton *button = nil;
                            if (lastRandom!=-1) {
                                button = [self.buttons objectAtIndex:lastRandom];
                                if ([self.selectedset indexOfObject:button]!=NSNotFound) {
                                    button.superview.backgroundColor = [UIColor redColor];
                                } else {
                                    button.superview.backgroundColor = lastColor;
                                }
                                button.superview.alpha = 0.5f;
                            }
                            cardview = [self.cards objectAtIndex:randomNumber];
                            button = [self.buttons objectAtIndex:randomNumber];
                            [self.currentset addObject:button];
                            lastColor = cardview.backgroundColor;
                            cardview.backgroundColor = [UIColor redColor];
                            cardview.alpha = 0.8f;
                            lastRandom = randomNumber;
                        });
                        if (500000-(run*5000)>150000)
                            usleep(500000-(run*5000));
                        else
                            usleep(150000);
                    }
                    if (lastRandom!=-1) {
                        UIButton __block *button = [self.buttons objectAtIndex:lastRandom];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([self.selectedset indexOfObject:button]==NSNotFound) {
                                button.superview.backgroundColor = lastColor;
                                //NSLog(@"last reset");
                            }
                            button.superview.alpha = 0.5f;
                        });
                    }
                    countdown = YES;
                });
            });
            while(!countdown)
                usleep(20000);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:(float)((float)delay/(float)1000000) delay:0 options:UIViewAnimationOptionCurveLinear  animations:^{
                    self.progressbar.frame = CGRectMake(self.view.frame.size.width/3.0f,self.gridSquare.frame.origin.y+self.gridSquare.frame.size.height+30.0f,0.0f,10.0f);
                } completion:^(BOOL finished) {
                    
                }];
            });
            
            usleep(delay);
            
            BOOL gameover = NO;
            if ([self.currentset count]!=[self.selectedset count]) {
                gameover = YES;
            } else {
                for(int n = 0; n < 3; n++) {
                    UIButton *currentb = [self.currentset objectAtIndex:n];
                    UIButton *selectedb = [self.selectedset objectAtIndex:n];
                    if (currentb!=selectedb)
                        gameover = YES;
                }
            }
            
            if (gameover) {
                AudioServicesPlaySystemSound(loseEffect);
                break;
            } else {
            }
            
            if (run>[self.highscore intValue]) {
                self.highscore = [NSNumber numberWithInt:run];
                [[NSUserDefaults standardUserDefaults] setObject:self.highscore forKey:@"highscore"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.highscorelabel.text = [NSString stringWithFormat:@"%@\nhigh",self.highscore];
                });
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //for(UIButton *button in self.currentset) {
                    //button.superview.backgroundColor = [UIColor redColor];
                    //button.superview.alpha = 0.8f;
                //}
            });
            
            run++;
            if (level*10==run) {
                AudioServicesPlaySystemSound(winEffect);
                level++;
                if (sqr<8)
                    sqr++;
            } else {
                AudioServicesPlaySystemSound(smallwinEffect);
            }
            
            usleep(250000);
        }
        //NSLog(@"game over");
        dispatch_async(dispatch_get_main_queue(), ^{
            for(UIButton *button in self.buttons) {
                button.hidden = YES;
            }
            self.playButton.hidden = NO;
        });
    });
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self greatRun];
}

-(void)onCard:(UIButton*)button {
}

-(void)onCardDown:(UIButton*)button {
    AudioServicesPlaySystemSound(audioEffect);
    @synchronized(self) {
        [self.selectedset addObject:button];
        [button.superview setBackgroundColor:[UIColor redColor]];
    }
}

- (void)setCardsNumber:(int)number {
    if (self.cards) {
        for(UIView *card in self.cards) {
            [card removeFromSuperview];
        }
    }
    self.cards = [[NSMutableArray alloc] init];
    self.buttons = [[NSMutableArray alloc] init];
    for(int n = 0; n < number; n++) {
        UIView *cardview = [[UIView alloc] init];
        cardview.layer.cornerRadius = 10.0f;
        cardview.alpha = 0.5f;
        
        CGFloat red = arc4random_uniform(255) / 255.0;
        CGFloat green = arc4random_uniform(255) / 255.0;
        CGFloat blue = arc4random_uniform(255) / 255.0;
        cardview.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
        
        [self.cards addObject:cardview];
        [self.gridSquare addSubview:cardview];
    }
    [self rearrangeCards];
}

-(void)rearrangeCards {
    CGFloat offset = 3.0f;
    
    int sqr = sqrt([self.cards count]);
    //NSLog(@"s(%d)",sqr);
    CGRect cardRect = CGRectMake(0.0f,0.0f,
                                  self.gridSquare.frame.size.width/sqr,
                                  self.gridSquare.frame.size.width/sqr);
    int index = 0;
    for(int y = 0; y < sqr; y++) {
        for(int x = 0; x < sqr; x++) {
            UIView *cardview = [self.cards objectAtIndex:index];
            cardview.frame = CGRectMake(cardRect.origin.x+offset,
                                        cardRect.origin.y+offset,
                                        cardRect.size.width-(offset*2.0f),
                                        cardRect.size.height-(offset*2.0f));
            UIButton *button = [[UIButton alloc] initWithFrame:cardview.bounds];
            [self.buttons addObject:button];
            [cardview addSubview:button];
            [button addTarget:self
                       action:@selector(onCard:)
             forControlEvents:UIControlEventTouchUpInside];
            [button addTarget:self
                       action:@selector(onCardDown:)
             forControlEvents:UIControlEventTouchDown];
            cardRect.origin.x+=self.gridSquare.frame.size.width/sqr;
            cardview.layer.cornerRadius = cardview.frame.size.width/2.0f;
            index++;
        }
        cardRect.origin.y+=self.gridSquare.frame.size.width/sqr;
        cardRect.origin.x = 0.0f;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
