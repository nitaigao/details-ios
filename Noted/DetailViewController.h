//
//  DetailViewController.h
//  Noted
//
//  Created by Nicholas Kostelnik on 08/11/2013.
//  Copyright (c) 2013 Nicholas Kostelnik. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
