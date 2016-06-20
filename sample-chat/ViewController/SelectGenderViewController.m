//
//  SelectGenderViewController.m
//  samplechat
//
//  Created by Goal on 6/19/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "SelectGenderViewController.h"

@interface SelectGenderViewController ()

@property (weak, nonatomic) IBOutlet UIButton *femaleLabel;
@property (weak, nonatomic) IBOutlet UIButton *maleLabel;
@property (weak, nonatomic) IBOutlet UIButton *startLabel;
- (IBAction)femaleBtnClick:(id)sender;
- (IBAction)maleBtnClick:(id)sender;
- (IBAction)startBtnClick:(id)sender;
@property UIColor *borderColor;
@property bool gender;   // false: female, true: male
@end

@implementation SelectGenderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _gender = false;
    [self setStyle];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setStyle {
    _borderColor = [UIColor colorWithRed:1.0 green:0.73 blue:0.16 alpha:1.0];
    _femaleLabel.layer.cornerRadius = 30.0f;
    _femaleLabel.layer.masksToBounds = true;
    _maleLabel.layer.cornerRadius = 30.0f;
    _maleLabel.layer.masksToBounds = true;
    _startLabel.layer.cornerRadius = 30.0f;
    _startLabel.layer.masksToBounds = true;

}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)femaleBtnClick:(id)sender {
    _femaleLabel.layer.borderWidth = 2.0f;
    _femaleLabel.layer.borderColor = _borderColor.CGColor;
    _maleLabel.layer.borderWidth = 0.0f;
    _gender = false;
}

- (IBAction)maleBtnClick:(id)sender {
    _maleLabel.layer.borderWidth = 2.0f;
    _maleLabel.layer.borderColor = _borderColor.CGColor;
    _femaleLabel.layer.borderWidth = 0.0f;
    _gender = true;
}

- (IBAction)startBtnClick:(id)sender {
}
@end
