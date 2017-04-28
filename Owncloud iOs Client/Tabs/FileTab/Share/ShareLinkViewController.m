//
//  ShareLinkViewController.m
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


#import "ShareLinkViewController.h"
#import "Owncloud_iOs_Client-Swift.h"
#import "UtilsFramework.h"
#import "ManageFilesDB.h"
#import "UtilsUrls.h"
#import "ManageSharesDB.h"

#define shareLinkViewNibName @"ShareLinkViewController"

//Cells and Sections
#define shareLinkOptionIdentifer @"ShareLinkOptionIdentifier"
#define shareLinkOptionNib @"ShareLinkOptionCell"

//#define shareLinkButtonIdentifier @"ShareLinkButtonIdentifier"
//#define shareLinkButtonNib @"ShareLinkButtonCell"
//#define heightOfShareLinkButtonRow 40.0

#define heightOfShareLinkOptionRow 55.0f
#define heightOfShareLinkOptionSection 10.0f
#define heightOfShareLinkOptionTitleFirstSection 55.0f


//Nº of Rows
#define optionsShownWithShareLinkEnableAndAllowEditing 4
#define optionsShownWithShareLinkEnableWithoutAllowEditing 3
#define optionsShownWithShareLinkDisable 0

//Date server format
#define dateServerFormat @"YYYY-MM-dd"

//alert share password
#define password_alert_view_tag 601

//permissions value to not update them
#define k_permissions_do_not_update 0

//mail subject key
#define k_subject_key_activityView @"subject"

//tools
#define standardDelay 0.2
#define animationsDelay 0.5
#define largeDelay 1.0


@interface ShareLinkViewController ()

@property (nonatomic) BOOL isPasswordProtectEnabled;
@property (nonatomic) BOOL isExpirationDateEnabled;

@property (nonatomic) NSInteger optionsShownWithShareLink;

@property (nonatomic) BOOL isAllowEditingEnabled;
@property (nonatomic) BOOL isAllowEditingShown;


@end

@implementation ShareLinkViewController


- (id) initWithFileDto:(FileDto *)fileDto andOCSharedDto:(OCSharedDto *)sharedDto andLinkOptionsViewMode:(LinkOptionsViewMode)linkOptionsViewMode {
    
    if ((self = [super initWithNibName:shareLinkViewNibName bundle:nil]))
    {
        _linkOptionsViewMode = linkOptionsViewMode;
        _sharedItem = fileDto;
        _updatedOCShare = sharedDto;
        
        _isPasswordProtectEnabled = false;
        _isExpirationDateEnabled = false;

        _optionsShownWithShareLink = 0;
        
        _isAllowEditingEnabled = false;
        _isAllowEditingShown = false;
        
        _manageNetworkErrors = [ManageNetworkErrors new];
        _manageNetworkErrors.delegate = self;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setStyleView];
}


#pragma mark - Action Methods

- (void) didSelectCloseView {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void) reloadView {
    
    self.isPasswordProtectEnabled = false;
    self.isExpirationDateEnabled = false;
    
    self.isAllowEditingShown = false;
    self.isAllowEditingEnabled =false;

    [self.shareLinkOptionsTableView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - TableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    //if (indexPath.section == 0) {
        
    
    
//        ShareLinkOptionCell *shareLinkOptionCell = (ShareLinkOptionCell *)[tableView dequeueReusableCellWithIdentifier:shareLinkOptionIdentifer];
//        
//        if (shareLinkOptionCell == nil) {
//            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkOptionNib owner:self options:nil];
//            shareLinkOptionCell = (ShareLinkOptionCell *)[topLevelObjects objectAtIndex:0];
//        }
//        
//        //shareLinkOptionCell.fileName.text = [self.updatedOCShare.shareWithDisplayName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//        
//        shareLinkOptionCell.optionName = self.updatedOCShare.name;
//        shareLinkOptionCell.
//        cell = shareLinkOptionCell;
        
   // }
    
    return [self getCellOptionShareLinkByTableView:tableView andIndex:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
             return heightOfShareLinkOptionTitleFirstSection;
            break;
        default:
             return heightOfShareLinkOptionSection;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return heightOfShareLinkOptionRow;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    NSString *title = nil;
    
    switch (section) {
        case 0:
            title = NSLocalizedString(@"title_share_link_option_name", nil);;
            break;
        case 1:
            title = NSLocalizedString(@"title_share_link_option_password", nil);
            break;
        case 2:
            title = NSLocalizedString(@"title_share_link_option_expiration", nil);
            break;
        case 3:
            title = NSLocalizedString(@"title_share_link_option_allow_editing", nil);
            break;
            
        default:
            break;
    }
    
    return title;
}

#pragma mark - cells

- (UITableViewCell *) getCellOptionShareLinkByTableView:(UITableView *) tableView andIndex:(NSIndexPath *) indexPath {
    //TODO:update with data
    ShareLinkOptionCell* shareLinkOptionCell = [tableView dequeueReusableCellWithIdentifier:shareLinkOptionIdentifer];

    if (shareLinkOptionCell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkOptionNib owner:self options:nil];
        shareLinkOptionCell = (ShareLinkOptionCell *)[topLevelObjects objectAtIndex:0];
    }

    [shareLinkOptionCell.optionSwith removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];

    switch (indexPath.section) {
        case 0:
            shareLinkOptionCell.optionName.hidden = YES;
            shareLinkOptionCell.optionDetail.hidden = YES;
            shareLinkOptionCell.optionSwith.hidden = YES;
            shareLinkOptionCell.textFieldNameLink.hidden = NO;
            shareLinkOptionCell.textFieldNameLink.placeholder = NSLocalizedString(@"title_share_link_option_name", nil);
            break;

        case 1:
            shareLinkOptionCell.optionName.text = NSLocalizedString(@"title_share_link_option_password", nil);

            if (self.isPasswordProtectEnabled) {
                shareLinkOptionCell.optionName.textColor = [UIColor blackColor];
                shareLinkOptionCell.optionDetail.textColor = [UIColor blackColor];
                shareLinkOptionCell.optionDetail.text = NSLocalizedString(@"secured_link", nil);
            } else {
                shareLinkOptionCell.optionName.textColor = [UIColor grayColor];
                shareLinkOptionCell.optionDetail.textColor = [UIColor grayColor];
                shareLinkOptionCell.optionDetail.text = @"";
            }
            [shareLinkOptionCell.optionSwith setOn:self.isPasswordProtectEnabled animated:false];

 //           [shareLinkOptionCell.optionSwith addTarget:self action:@selector(passwordProtectedSwithValueChanged:) forControlEvents:UIControlEventValueChanged];

            break;

        case 2:
            shareLinkOptionCell.optionName.text = NSLocalizedString(@"title_share_link_option_expiration", nil);

            if (self.isAllowEditingEnabled) {
                shareLinkOptionCell.optionName.textColor = [UIColor blackColor];
                shareLinkOptionCell.optionDetail.textColor = [UIColor blackColor];
            } else {
                shareLinkOptionCell.optionName.textColor = [UIColor grayColor];
                shareLinkOptionCell.optionDetail.textColor = [UIColor grayColor];
            }
            shareLinkOptionCell.optionDetail.text = @"";
//            [shareLinkOptionCell.optionSwith setOn:self.isAllowEditingEnabled animated:false];

            [shareLinkOptionCell.optionSwith addTarget:self action:@selector(allowEditingSwithValueChanged:) forControlEvents:UIControlEventValueChanged];

            break;
            
        case 3:
            shareLinkOptionCell.optionName.text = NSLocalizedString(@"title_share_link_option_allow_editing", nil);
            
            if (self.isAllowEditingEnabled) {
                shareLinkOptionCell.optionName.textColor = [UIColor blackColor];
                shareLinkOptionCell.optionDetail.textColor = [UIColor blackColor];
            } else {
                shareLinkOptionCell.optionName.textColor = [UIColor grayColor];
                shareLinkOptionCell.optionDetail.textColor = [UIColor grayColor];
            }
            shareLinkOptionCell.optionDetail.text = @"";
            //            [shareLinkOptionCell.optionSwith setOn:self.isAllowEditingEnabled animated:false];
            
            [shareLinkOptionCell.optionSwith addTarget:self action:@selector(allowEditingSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            break;

        default:
            //Not expected
            DLog(@"Not expected");
            break;
    }

    return shareLinkOptionCell;

}


#pragma mark - Select options

- (void) didSelectSetExpirationDateLink {
    [self launchDatePicker];
}

- (void) didSelectSetPasswordLink {
    [self showPasswordView];
}


#pragma mark - Accessory alert views

- (void) showPasswordView {
    
    if (self.passwordView != nil) {
        self.passwordView = nil;
    }
    
    self.passwordView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"shared_link_protected_title", nil)
                                                  message:nil delegate:self
                                        cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                                        otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
    
    self.passwordView.tag = password_alert_view_tag;
    self.passwordView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [self.passwordView textFieldAtIndex:0].delegate = self;
    [[self.passwordView textFieldAtIndex:0] setAutocorrectionType:UITextAutocorrectionTypeNo];
    [[self.passwordView textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [[self.passwordView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDefault];
    [[self.passwordView textFieldAtIndex:0] setKeyboardAppearance:UIKeyboardAppearanceLight];
    [[self.passwordView textFieldAtIndex:0] setSecureTextEntry:true];
    
    [self.passwordView show];
}

#pragma mark -

- (void) updateSharedLinkWithPassword:(NSString*) password expirationDate:(NSString*)expirationDate permissions:(NSInteger)permissions{
    
//    if (self.sharedFileOrFolder == nil) {
//        self.sharedFileOrFolder = [ShareFileOrFolder new];
//        self.sharedFileOrFolder.delegate = self;
//    }
//    
//    self.sharedFileOrFolder.parentViewController = self;
//    
//    self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
//    
//    OCSharedDto *ocShare = [ManageSharesDB getTheOCShareByFileDto:self.sharedItem andShareType:shareTypeLink andUser:APP_DELEGATE.activeUser];
//    
//    [self.sharedFileOrFolder updateShareLink:ocShare withPassword:password expirationTime:expirationDate permissions:permissions];
    
}

#pragma mark - switch changes

- (void) passwordProtectedSwithValueChanged:(UISwitch*) sender{
    
    if (self.isPasswordProtectEnabled){
        
        if (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported) {
            OCCapabilities *cap = APP_DELEGATE.activeUser.capabilitiesDto;
            
            if (cap.isFilesSharingPasswordEnforcedEnabled) {
                //not remove, is enforced password
                sender.on = true;
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"shared_link_cannot_remove_password", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                [alertView show];
                return;
            }
        }
        
        //Remove password Protected
        [self updateSharedLinkWithPassword:@"" expirationDate:nil permissions:k_permissions_do_not_update];
        
    } else {
        //Update with password protected
        [self showPasswordView];
    }
}

- (void) expirationTimeSwithValueChanged:(UISwitch*) sender{
    
    if (self.isExpirationDateEnabled) {
        if (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported) {
            OCCapabilities *cap = APP_DELEGATE.activeUser.capabilitiesDto;
            
            if (cap.isFilesSharingExpireDateEnforceEnabled) {
                //not remove, is enforced expiration date
                sender.on = true;
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"shared_link_cannot_remove_expiration_date", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                [alertView show];
                return;
            }
        }
        
        //Remove expiration date
        [self updateSharedLinkWithPassword:nil expirationDate:@"" permissions:k_permissions_do_not_update];
        
    } else {
        //Update with expiration date
        [self launchDatePicker];
    }
    
}

- (void) allowEditingSwithValueChanged:(UISwitch*) sender{
    
    if (self.isAllowEditingEnabled) {
        self.updatedOCShare.permissions = [UtilsFramework getPermissionsValueByCanEdit:NO andCanCreate:NO andCanChange:NO andCanDelete:NO andCanShare:NO andIsFolder:YES];
    } else {
        self.updatedOCShare.permissions = [UtilsFramework getPermissionsValueByCanEdit:YES andCanCreate:YES andCanChange:YES andCanDelete:NO andCanShare:NO andIsFolder:YES];
    }
    
    //update permissions
    [self updateSharedLinkWithPassword:nil expirationDate:nil permissions:self.updatedOCShare.permissions];
}


#pragma mark - convert

#pragma mark - Date Picker methods

- (void) launchDatePicker{
    
    static CGFloat controlToolBarHeight = 44.0;
    static CGFloat datePickerViewYPosition = 40.0;
    static CGFloat datePickerViewHeight = 300.0;
    static CGFloat pickerViewHeight = 250.0;
    static CGFloat deltaSpacerWidthiPad = 150.0;
    
    
    self.datePickerContainerView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.datePickerContainerView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.datePickerContainerView];
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [recognizer setNumberOfTapsRequired:1];
    recognizer.delegate = self;
    recognizer.cancelsTouchesInView = true;
    [self.datePickerContainerView addGestureRecognizer:recognizer];
    
    UIToolbar *controlToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, controlToolBarHeight)];
    [controlToolbar sizeToFit];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dateSelected:)];
    
    UIBarButtonItem *spacer;
    
    if (IS_IPHONE) {
        spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    }else{
        spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        CGFloat width = self.view.frame.size.width - deltaSpacerWidthiPad;
        spacer.width = width;
    }
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeDatePicker)];
    
    
    [controlToolbar setItems:[NSArray arrayWithObjects:cancelButton, spacer, doneButton, nil] animated:NO];
    
    if (self.datePickerView == nil) {
        self.datePickerView = [[UIDatePicker alloc] init];
        self.datePickerView.datePickerMode = UIDatePickerModeDate;
        
        NSDateComponents *deltaComps = [NSDateComponents new];
        [deltaComps setDay:1];
        NSDate *tomorrow = [[NSCalendar currentCalendar] dateByAddingComponents:deltaComps toDate:[NSDate date] options:0];
        
        self.datePickerView.minimumDate = tomorrow;
    }
    
    [self.datePickerView setFrame:CGRectMake(0, datePickerViewYPosition, self.view.frame.size.width, datePickerViewHeight)];
    
    if (!self.pickerView) {
        self.pickerView = [[UIView alloc] initWithFrame:self.datePickerView.frame];
    } else {
        [self.pickerView setHidden:NO];
    }
    
    
    [self.pickerView setFrame:CGRectMake(0,
                                         self.view.frame.size.height,
                                         self.view.frame.size.width,
                                         pickerViewHeight)];
    
    [self.pickerView setBackgroundColor: [UIColor whiteColor]];
    [self.pickerView addSubview: controlToolbar];
    [self.pickerView addSubview: self.datePickerView];
    [self.datePickerView setHidden: false];
    
    [self.datePickerContainerView addSubview:self.pickerView];
    
    [UIView animateWithDuration:animationsDelay
                     animations:^{
                         [self.pickerView setFrame:CGRectMake(0,
                                                              self.view.frame.size.height - self.pickerView.frame.size.height,
                                                              self.view.frame.size.width,
                                                              pickerViewHeight)];
                     }
                     completion:nil];
    
}


- (void) dateSelected:(UIBarButtonItem *)sender{
    
    [self closeDatePicker];
    
    NSString *dateString = [self convertDateInServerFormat:self.datePickerView.date];
    
    [self updateSharedLinkWithPassword:nil expirationDate:dateString permissions:k_permissions_do_not_update];
    
}

- (void) closeDatePicker {
    [UIView animateWithDuration:animationsDelay animations:^{
        [self.pickerView setFrame:CGRectMake(self.pickerView.frame.origin.x,
                                             self.view.frame.size.height,
                                             self.pickerView.frame.size.width,
                                             self.pickerView.frame.size.height)];
    } completion:^(BOOL finished) {
        [self.datePickerContainerView removeFromSuperview];
    }];
    
    [self updateInterfaceWithShareLinkStatus];
    
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    [self.datePickerContainerView removeGestureRecognizer:sender];
    [self closeDatePicker];
}

#pragma mark -

- (void) updateInterfaceWithShareLinkStatus {

    self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];

    if ([ManageSharesDB getTheOCShareByFileDto:self.sharedItem andShareType:shareTypeLink andUser:APP_DELEGATE.activeUser]) {

        self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];

//        if (self.sharedFileOrFolder == nil) {
//            self.sharedFileOrFolder = [ShareFileOrFolder new];
//            self.sharedFileOrFolder.delegate = self;
//        }

        self.updatedOCShare = [ManageSharesDB getTheOCShareByFileDto:self.sharedItem andShareType:shareTypeLink andUser:APP_DELEGATE.activeUser];

        if (![ self.updatedOCShare.shareWith isEqualToString:@""] && ![ self.updatedOCShare.shareWith isEqualToString:@"NULL"]  &&  self.updatedOCShare.shareType == shareTypeLink) {
            self.isPasswordProtectEnabled = true;
        }else{
            self.isPasswordProtectEnabled = false;
        }

        if (self.updatedOCShare.expirationDate == 0.0) {
            self.isExpirationDateEnabled = false;
        }else {
            self.isExpirationDateEnabled = true;
        }

        //self.isAllowEditingShown = [self hasAllowEditingToBeShown];
        //self.isAllowEditingEnabled = [UtilsFramework isPermissionToReadCreateUpdate:self.updatedOCShare.permissions];

    }

    //[self updateSharesOfFileFromDB];

    [self reloadView];

}


#pragma mark - convert format of date

- (NSString *) convertDateInServerFormat:(NSDate *)date {
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    
    [dateFormatter setDateFormat:dateServerFormat];
    
    return [dateFormatter stringFromDate:date];
}


- (NSString *) stringOfDate:(NSDate *) date {
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    NSLocale *locale = [NSLocale currentLocale];
    [dateFormatter setLocale:locale];
    
    return [dateFormatter stringFromDate:date];
}

#pragma mark - Style Methods

- (void) setStyleView {
    
    self.navigationItem.title = (self.linkOptionsViewMode == LinkOptionsViewModeCreate) ? NSLocalizedString(@"title_view_create_link", nil) :  NSLocalizedString(@"title_view_edit_link", nil) ;
    [self setBarButtonStyle];
    
}

- (void) setBarButtonStyle {
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didSelectCloseView)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
