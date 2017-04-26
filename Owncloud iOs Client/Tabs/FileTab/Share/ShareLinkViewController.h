//
//  ShareLinkViewController.h
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 25/04/17.
//
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>
#import "OCSharedDto.h"

@interface ShareLinkViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ManageNetworkErrorsDelegate>


@property (weak, nonatomic) IBOutlet UITableView* shareLinkOptionsTableView;

@property (strong, nonatomic) UIView* datePickerContainerView;
@property (strong, nonatomic) UIDatePicker *datePickerView;
@property (strong, nonatomic) UIView* pickerView;
@property (nonatomic, strong) UIAlertView *passwordView;

@property (nonatomic, strong) FileDto* sharedItem;
@property (nonatomic, strong) OCSharedDto *updatedOCShare;

@property (nonatomic, strong) ManageNetworkErrors *manageNetworkErrors;

- (id) initWithFileDto:(FileDto *)fileDto andOCSharedDto:(OCSharedDto *)sharedDto;

@end
