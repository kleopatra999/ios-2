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
#import "UtilsFramework.h"

#define shareLinkViewNibName @"ShareLinkViewController"

//Cells and Sections
#define shareLinkOptionIdentifer @"ShareLinkOptionIdentifier"
#define shareLinkOptionNib @"ShareLinkOptionCell"
#define nOfSectionsWithAllOptionsAvailable 4


//#define shareLinkButtonIdentifier @"ShareLinkButtonIdentifier"
//#define shareLinkButtonNib @"ShareLinkButtonCell"
//#define heightOfShareLinkButtonRow 40.0

#define heightOfShareLinkOptionRow 55.0f
#define heightOfShareLinkOptionSection 15.0f
#define heightOfShareLinkOptionTitleFirstSection 55.0f

//Date server format
#define dateServerFormat @"YYYY-MM-dd"

//permissions value to not update them
#define k_permissions_do_not_update 0

//mail subject key
#define k_subject_key_activityView @"subject"

//tools
#define standardDelay 0.2
#define animationsDelay 0.5
#define largeDelay 1.0

typedef NS_ENUM (NSInteger, LinkOption){
    LinkOptionName,
    LinkOptionPassword,
    LinkOptionExpiration,
    LinkOptionAllowUploads
};


@interface ShareLinkViewController ()

@property (nonatomic) BOOL isPasswordProtectEnabled;
@property (nonatomic) BOOL isExpirationDateEnabled;

@property (nonatomic) NSInteger optionsShownWithShareLink;

@property (nonatomic) BOOL isAllowEditingEnabled;

@property (nonatomic, strong) UIPopoverController* activityPopoverController;


@end

@implementation ShareLinkViewController


- (id) initWithFileDto:(FileDto *)fileDto andOCSharedDto:(OCSharedDto *)sharedDto andLinkOptionsViewMode:(LinkOptionsViewMode)linkOptionsViewMode {
    
    if ((self = [super initWithNibName:shareLinkViewNibName bundle:nil]))
    {
        _linkOptionsViewMode = linkOptionsViewMode;
        _fileShared = fileDto;
        _sharedDto = sharedDto;
        _updatedSharedDto = [[OCSharedDto alloc] initWithSharedDto:sharedDto];
        
        if (self.linkOptionsViewMode == LinkOptionsViewModeCreate) {
            
            self.isPasswordProtectEnabled = NO;
            self.isExpirationDateEnabled = NO;
            self.isAllowEditingEnabled = NO;
            
        } else {
            
            if (![self.sharedDto.shareWith isEqualToString:@""] && ![ self.sharedDto.shareWith isEqualToString:@"NULL"]) {
                self.isPasswordProtectEnabled = YES;
            }else{
                self.isPasswordProtectEnabled = NO;
            }
            
            [self updateEnabledOptions];
        }
//        _manageNetworkErrors = [ManageNetworkErrors new];
//        _manageNetworkErrors.delegate = self;
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
- (void) reloadView {

    [self.shareLinkOptionsTableView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(NSInteger) getNumberOfOptionsAvailable {
    
    NSInteger nOfOptionsAvailable = nOfSectionsWithAllOptionsAvailable;
    
    if (![self hasOptionLinkNameToBeShown]) {
        nOfOptionsAvailable = nOfOptionsAvailable -1;
    }
    
    if (![self hasOptionAllowEditingToBeShown]) {
        nOfOptionsAvailable = nOfOptionsAvailable -1;
    }
    
    return nOfOptionsAvailable;
}


#pragma mark - TableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return [self getNumberOfOptionsAvailable];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return [self getCellOptionShareLinkByTableView:tableView andIndex:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 2 && self.isExpirationDateEnabled) {
        //the user want to change the current expiration date
        [self didSelectSetExpirationDateLink];
    }
    
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
            if ([self hasOptionLinkNameToBeShown]) {
                title = NSLocalizedString(@"title_share_link_option_name", nil);;
            } else {
                title = NSLocalizedString(@"title_share_link_option_password", nil);;
            }
            break;
        case 1:
            if ([self hasOptionLinkNameToBeShown]) {
                title = NSLocalizedString(@"title_share_link_option_password", nil);
            } else {
                title = NSLocalizedString(@"title_share_link_option_expiration", nil);
            }
            break;
        case 2:
            title = NSLocalizedString(@"title_share_link_option_expiration", nil);
            break;
            
        default:
            break;
    }
    
    return title;
}

#pragma mark - cells

- (UITableViewCell *) getCellOptionShareLinkByTableView:(UITableView *) tableView andIndex:(NSIndexPath *) indexPath {
    //TODO:update with data in other class
    ShareLinkOptionCell* shareLinkOptionCell = [tableView dequeueReusableCellWithIdentifier:shareLinkOptionIdentifer];

    if (shareLinkOptionCell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkOptionNib owner:self options:nil];
        shareLinkOptionCell = (ShareLinkOptionCell *)[topLevelObjects objectAtIndex:0];
    }

    [shareLinkOptionCell.optionSwith removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
    shareLinkOptionCell.tag = indexPath.section+1;
    
    switch (indexPath.section) {
            
        case 0:
            if ([self hasOptionLinkNameToBeShown]) {
                [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionName];
            } else {
                [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionPassword];
            }
            
            break;

        case 1:
            if ([self hasOptionLinkNameToBeShown]) {
                [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionPassword];
            } else {
                [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionExpiration];
            }
            break;

        case 2:
            if ([self hasOptionLinkNameToBeShown]) {
                [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionExpiration];
            } else {
                [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionAllowUploads];
            }
            break;
            
        case 3:
            [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionAllowUploads];
            
          
            break;

        default:
            break;
    }

    return shareLinkOptionCell;
}

- (ShareLinkOptionCell *) getUpdatedCell:(ShareLinkOptionCell *)shareLinkOptionCell toOption:(LinkOption)linkOption {
    
    switch (linkOption) {
            
        case LinkOptionName:
            
            shareLinkOptionCell.optionTextField.hidden = NO;
            shareLinkOptionCell.optionTextField.placeholder = NSLocalizedString(@"placeholder_share_link_option_name", nil);
            if (self.linkOptionsViewMode == LinkOptionsViewModeEdit) {
                shareLinkOptionCell.optionTextField.text = self.updatedSharedDto.name;
            }
            
            break;
        
        case LinkOptionPassword:
            
            shareLinkOptionCell.optionTextField.hidden = NO;
            shareLinkOptionCell.optionSwith.hidden = NO;
            [shareLinkOptionCell.optionSwith setOn:self.isPasswordProtectEnabled animated:false];
            
            [shareLinkOptionCell.optionSwith addTarget:self action:@selector(passwordProtectedSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            if (self.isPasswordProtectEnabled) {
                shareLinkOptionCell.optionTextField.secureTextEntry = YES;
                shareLinkOptionCell.optionTextField.placeholder = @"**********";
                shareLinkOptionCell.optionTextField.userInteractionEnabled = YES;
            } else {
                shareLinkOptionCell.optionTextField.secureTextEntry = YES;
                shareLinkOptionCell.optionTextField.placeholder = NSLocalizedString(@"placeholder_share_link_option_password", nil);
                shareLinkOptionCell.optionTextField.userInteractionEnabled = NO;
            }
            
            break;
        
        case LinkOptionExpiration:
            
            shareLinkOptionCell.optionTextField.placeholder = NSLocalizedString(@"placeholder_share_link_option_expiration", nil);
            shareLinkOptionCell.optionSwith.hidden = NO;
            [shareLinkOptionCell.optionSwith setOn:self.isExpirationDateEnabled animated:false];
            [shareLinkOptionCell.optionSwith addTarget:self action:@selector(expirationTimeSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            if (self.isExpirationDateEnabled) {
                shareLinkOptionCell.optionTextField.hidden = YES;
                shareLinkOptionCell.optionName.hidden = NO;
                shareLinkOptionCell.optionName.text = [self stringOfDate:[NSDate dateWithTimeIntervalSince1970: self.updatedSharedDto.expirationDate]];
            } else {
                shareLinkOptionCell.optionName.hidden = YES;
                shareLinkOptionCell.optionTextField.hidden = NO;
                shareLinkOptionCell.optionTextField.allowsEditingTextAttributes = NO;
                shareLinkOptionCell.optionTextField.userInteractionEnabled = NO;
            }
            
            break;
        
        case LinkOptionAllowUploads:
            
            shareLinkOptionCell.optionName.hidden = NO;
            shareLinkOptionCell.optionName.text = NSLocalizedString(@"title_share_link_option_allow_editing", nil);
            shareLinkOptionCell.optionSwith.hidden = NO;
            [shareLinkOptionCell.optionSwith setOn:self.isAllowEditingEnabled animated:false];
            [shareLinkOptionCell.optionSwith addTarget:self action:@selector(allowEditingSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            break;
            
        default:
            break;
    }
    
    return shareLinkOptionCell;
}

#pragma mark - Select options

- (void) didSelectSetExpirationDateLink {
    [self launchDatePicker];
}

- (void) didSelectSaveShareLink {
    
    if (self.linkOptionsViewMode == LinkOptionsViewModeCreate) {
        
        [ShareUtils createNewShareLink:self.updatedSharedDto ofFile:self.fileShared];
    } else {
        [self updateShareOptionsNeeded];
    }
    
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void) didSelectCloseView {
    [self dismissViewControllerAnimated:true completion:nil];
}


#pragma mark - Network requests 
//TODO: move to other class notsharedFileOrFolder

- (void) updateShareOptionsNeeded {

    //NAME
    ShareLinkOptionCell *cellName = [self.shareLinkOptionsTableView viewWithTag:1];
    NSString *stringName = cellName.optionTextField.text;
    if (![stringName isEqualToString:self.sharedDto.name]) {
        
        [self updateSharedLinkWithPassword:nil expirationDate:nil permissions:k_permissions_do_not_update andLinkName:stringName];
    }
    
    //PASSWORD
    if (self.isPasswordProtectEnabled) {
        
        ShareLinkOptionCell *cellPassword = [self.shareLinkOptionsTableView viewWithTag:2];
        if (![cellPassword.optionTextField.text isEqualToString:@""]) {
            [self updateSharedLinkWithPassword:cellPassword.optionTextField.text expirationDate:nil permissions:k_permissions_do_not_update andLinkName:nil];
        }
        
    } else {
        [self updateSharedLinkWithPassword:@"" expirationDate:nil permissions:k_permissions_do_not_update andLinkName:nil];
    }
    
    //EXPIRATION
    if (self.updatedSharedDto.expirationDate != self.sharedDto.expirationDate) {
        if (self.isExpirationDateEnabled) {
            NSString *dateString = [self stringOfDate:[NSDate dateWithTimeIntervalSince1970: self.updatedSharedDto.expirationDate]];
            [self updateSharedLinkWithPassword:nil expirationDate:dateString permissions:k_permissions_do_not_update andLinkName:nil];
        } else {
            [self updateSharedLinkWithPassword:nil expirationDate:@"" permissions:k_permissions_do_not_update andLinkName:nil];
        }
    }
    
    //ALLOW UPLOADS
    if (self.updatedSharedDto.permissions != self.sharedDto.permissions) {
        if (self.updatedSharedDto.isDirectory) {
            [self updateSharedLinkWithPassword:nil expirationDate:nil permissions:self.updatedSharedDto.permissions andLinkName:nil];
        }
    }
    
}

- (void) updateSharedLinkWithPassword:(NSString*)password expirationDate:(NSString*)expirationDate permissions:(NSInteger)permissions andLinkName:(NSString *)linkName {
    
    [self.sharedFileOrFolder updateShareLink:self.updatedSharedDto withPassword:password expirationTime:expirationDate permissions:permissions andLinkName:linkName successRequest:^(NSData *responseData) {
        //
    } failureRequest:^(NSError *error) {
        //
    }];
    
    //TODO: return state and reloadview in mainviewcontroller
    
}


#pragma mark - switch changes

- (void) passwordProtectedSwithValueChanged:(UISwitch*) sender{
    
    if (self.isPasswordProtectEnabled){
        
        OCCapabilities *cap = APP_DELEGATE.activeUser.capabilitiesDto;
        
        if (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && cap.isFilesSharingPasswordEnforcedEnabled) {
            
            //not remove, is enforced password
            sender.on = true;
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"shared_link_cannot_remove_password", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [alertView show];
            return;
            //TODO: show in new alert cell this message
        } else {
            self.isPasswordProtectEnabled = NO;
        }
    } else {
        self.isPasswordProtectEnabled = YES;
    }
    
    [self updateInterfaceWithShareOptionsLinkStatus];

}

- (void) expirationTimeSwithValueChanged:(UISwitch*) sender{
    
    if (self.isExpirationDateEnabled) {
        //Remove expiration date
        if (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported) {
            OCCapabilities *cap = APP_DELEGATE.activeUser.capabilitiesDto;
            
            if (cap.isFilesSharingExpireDateEnforceEnabled) {
                //not remove, is enforced expiration date
                self.isExpirationDateEnabled = YES;
                sender.on = YES;
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"shared_link_cannot_remove_expiration_date", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                [alertView show];
                return;
            } else {
                self.updatedSharedDto.expirationDate = 0.0;
                [self updateInterfaceWithShareOptionsLinkStatus];
            }
        } else {
            self.updatedSharedDto.expirationDate = 0.0;
            [self updateInterfaceWithShareOptionsLinkStatus];
        }
        
    } else {
        //after date selected in picker, current share object will be update and the view reloaded
        [self didSelectSetExpirationDateLink];
    }
    
}

- (void) allowEditingSwithValueChanged:(UISwitch*) sender{
    
    if (self.isAllowEditingEnabled) {
        self.isAllowEditingEnabled = NO;
        self.updatedSharedDto.permissions = [UtilsFramework getPermissionsValueByCanEdit:NO andCanCreate:NO andCanChange:NO andCanDelete:NO andCanShare:NO andIsFolder:YES];
    } else {
        self.isAllowEditingEnabled = YES;
        self.updatedSharedDto.permissions = [UtilsFramework getPermissionsValueByCanEdit:YES andCanCreate:YES andCanChange:YES andCanDelete:NO andCanShare:NO andIsFolder:YES];
    }

}


#pragma mark - update UI

- (void) updateEnabledOptions {
    
    if (self.updatedSharedDto.expirationDate == 0.0) {
        self.isExpirationDateEnabled = NO;
    }else {
        self.isExpirationDateEnabled = YES;
    }

    self.isAllowEditingEnabled = [UtilsFramework isPermissionToReadCreateUpdate:self.updatedSharedDto.permissions];
}

- (void) updateInterfaceWithShareOptionsLinkStatus {
    
    [self updateEnabledOptions];

    [self reloadView];
}

#pragma mark - capabilities checks

- (BOOL) hasOptionAllowEditingToBeShown {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    if (((app.activeUser.hasCapabilitiesSupport != serverFunctionalitySupported) ||
         (app.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && app.activeUser.capabilitiesDto.isFilesSharingAllowPublicUploadsEnabled))
        && self.fileShared.isDirectory){
        return YES;
        
    } else {
        
        return NO;
    }
}

- (BOOL) hasOptionLinkNameToBeShown {

    if (APP_DELEGATE.activeUser.hasPublicShareLinkOptionNameSupport) {
        return YES;
    }
    
    return NO;
}

- (BOOL) hasMultipleShareLinkAvailable {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    if (app.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && app.activeUser.capabilitiesDto.isFilesSharingAllowUserCreateMultiplePublicLinksEnabled) {
        return YES;
        
    } else {
        
        return NO;
    }
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
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didSelectSaveShareLink)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(didSelectCloseView)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}


#pragma mark - UIGestureRecognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // test if our control subview is on-screen
    if ([touch.view isDescendantOfView:self.pickerView]) {
        // we touched our control surface
        return NO;
    }
    return YES;
}

#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    return YES;
}


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
    
    self.updatedSharedDto.expirationDate = [self.datePickerView.date timeIntervalSince1970];
    
    [self updateInterfaceWithShareOptionsLinkStatus];
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
    
    [self updateInterfaceWithShareOptionsLinkStatus];
    
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    [self.datePickerContainerView removeGestureRecognizer:sender];
    [self closeDatePicker];
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
