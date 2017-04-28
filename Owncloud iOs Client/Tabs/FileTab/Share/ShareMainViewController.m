//
//  ShareMainViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/8/15.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ShareMainViewController.h"
#import "ManageFilesDB.h"
#import "UtilsUrls.h"
#import "UserDto.h"
#import "OCSharedDto.h"
#import "Owncloud_iOs_Client-Swift.h"
#import "FileNameUtils.h"
#import "UIColor+Constants.h"
#import "OCNavigationController.h"
#import "ManageUsersDB.h"
#import "EditAccountViewController.h"
#import "Customization.h"
#import "ShareSearchUserViewController.h"
#import "ManageSharesDB.h"
#import "ManageCapabilitiesDB.h"
#import "ShareEditUserViewController.h"
#import "OCShareUser.h"
#import "ShareUtils.h"
#import "UtilsFramework.h"
#import "ShareLinkViewController.h"

//tools
#define standardDelay 0.2
#define animationsDelay 0.5
#define largeDelay 1.0

//Xib
#define shareMainViewNibName @"ShareViewController"

//Cells and Sections
#define shareFileCellIdentifier @"ShareFileIdentifier"
#define shareFileCellNib @"ShareFileCell"

#define shareLinkHeaderIdentifier @"ShareLinkHeaderIdentifier"
#define shareLinkHeaderNib @"ShareLinkHeaderCell"

#define shareUserCellIdentifier @"ShareUserCellIdentifier"
#define shareUserCellNib @"ShareUserCell"

#define shareMainLinkCellIdentifier @"ShareMainLinkCellIdentifier"
#define shareMainLinkCellNib @"ShareMainLinkCell"

#define heighOfFileDetailrow 120.0

#define heightOfShareMainLinkRow 55.0
#define heightOfShareWithUserRow 55.0

#define heightOfShareLinkHeader 45.0

#define shareTableViewSectionsNumber  3

//Nº of Rows
#define optionsShownWithShareLinkEnableAndAllowEditing 4
#define optionsShownWithShareLinkEnableWithoutAllowEditing 3
#define optionsShownWithShareLinkDisable 0

//Date server format
#define dateServerFormat @"YYYY-MM-dd"

//alert share password
#define password_alert_view_tag 601

//mail subject key
#define k_subject_key_activityView @"subject"

//permissions value to not update them
#define k_permissions_do_not_update 0


//typedef NS_ENUM(NSInteger, OCShareMainSection) {
//    OCShareMainSectionUsers,
//    OCShareMainSectionLinks,
//    OCShareMainSectionCount
//};

@interface ShareMainViewController ()

@property (nonatomic, strong) FileDto* sharedItem;
@property (nonatomic, strong) OCSharedDto *updatedOCShare;
@property (nonatomic, strong) NSString* sharedToken;
@property (nonatomic, strong) ShareFileOrFolder* sharedFileOrFolder;
@property (nonatomic, strong) MBProgressHUD* loadingView;
@property (nonatomic, strong) UIAlertView *passwordView;
@property (nonatomic, strong) UIActivityViewController *activityView;
@property (nonatomic, strong) EditAccountViewController *resolveCredentialErrorViewController;
@property (nonatomic, strong) UIPopoverController* activityPopoverController;
@property (nonatomic, strong) NSMutableArray *sharedUsersOrGroups;
@property (nonatomic, strong) NSMutableArray *sharedPublicLinks;
@property (nonatomic, strong) NSMutableArray *sharesOfFile;
@property (nonatomic) NSInteger permissions;

@end


@implementation ShareMainViewController


- (id) initWithFileDto:(FileDto *)fileDto {
    
    if ((self = [super initWithNibName:shareMainViewNibName bundle:nil]))
    {
        self.sharedItem = fileDto;
        self.sharedUsersOrGroups = [NSMutableArray new];
        self.sharedPublicLinks = [NSMutableArray new];
        self.sharesOfFile = [NSMutableArray new];
    }
    
    return self;
}

- (void) viewDidLoad{
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setStyleView];
    
    [self checkSharedStatusOFile];
    [self updateInterfaceWithShareLinkStatus ]; //TODO:recheck where use
}

- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}

- (BOOL) hasAllowEditingToBeShown {

    if (((APP_DELEGATE.activeUser.hasCapabilitiesSupport != serverFunctionalitySupported) ||
        (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && APP_DELEGATE.activeUser.capabilitiesDto.isFilesSharingAllowPublicUploadsEnabled))
        && self.sharedItem.isDirectory){
        return YES;
        
    } else {
        
        return NO;
    }
}




#pragma mark - Style Methods

- (void) setStyleView {
    
    self.navigationItem.title = NSLocalizedString(@"share_link_long_press", nil);
    [self setBarButtonStyle];
    
}

- (void) setBarButtonStyle {

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didSelectCloseView)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
}

- (void) reloadView {
    
    [self.shareTableView reloadData];
}

#pragma mark - 
- (void) updateInterfaceWithShareLinkStatus {
    
    self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
    
    if ([ManageSharesDB getTheOCShareByFileDto:self.sharedItem andShareType:shareTypeLink andUser:APP_DELEGATE.activeUser]) {
        
        self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
        
                if (self.sharedFileOrFolder == nil) {
                    self.sharedFileOrFolder = [ShareFileOrFolder new];
                    self.sharedFileOrFolder.delegate = self;
                }
        
        self.updatedOCShare = [ManageSharesDB getTheOCShareByFileDto:self.sharedItem andShareType:shareTypeLink andUser:APP_DELEGATE.activeUser];
        
//        if (![ self.updatedOCShare.shareWith isEqualToString:@""] && ![ self.updatedOCShare.shareWith isEqualToString:@"NULL"]  &&  self.updatedOCShare.shareType == shareTypeLink) {
//            self.isPasswordProtectEnabled = true;
//        }else{
//            self.isPasswordProtectEnabled = false;
//        }
//        
//        if (self.updatedOCShare.expirationDate == 0.0) {
//            self.isExpirationDateEnabled = false;
//        }else {
//            self.isExpirationDateEnabled = true;
//        }
        
        //self.isAllowEditingShown = [self hasAllowEditingToBeShown];
        //self.isAllowEditingEnabled = [UtilsFramework isPermissionToReadCreateUpdate:self.updatedOCShare.permissions];
        
    }
    
    [self updateSharesOfFileFromDB];
    
    [self reloadView];
    
}

- (void) updateSharesOfFileFromDB {
    
    NSString *path = [NSString stringWithFormat:@"/%@%@", [UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser], self.sharedItem.fileName];
    
    [self.sharedUsersOrGroups removeAllObjects];
    [self.sharesOfFile removeAllObjects];
    [self.sharedPublicLinks removeAllObjects];
    
    self.sharesOfFile = [ManageSharesDB getSharesByUser:APP_DELEGATE.activeUser.idUser andPath:path];
    
    DLog(@"Number of Shares of file: %lu", (unsigned long)self.sharesOfFile.count);
    
    for (OCSharedDto *shareItem in self.sharesOfFile) {
        
        if (shareItem.shareType == shareTypeUser || shareItem.shareType == shareTypeGroup || shareItem.shareType == shareTypeRemote) {
            
            
            OCShareUser *shareUser = [OCShareUser new];
            shareUser.name = shareItem.shareWith;
            shareUser.displayName = shareItem.shareWithDisplayName;
            shareUser.sharedDto = shareItem;
            shareUser.shareeType = shareItem.shareType;
            
            [self.sharedUsersOrGroups addObject:shareUser];
           // [self.sharedUsersOrGroups addObject:shareItem];
            
        } else if(shareItem.shareType == shareTypeLink){
            
            [self.sharedPublicLinks addObject:shareItem];
        }
    }
    
    self.sharedUsersOrGroups = [ShareUtils manageTheDuplicatedUsers:self.sharedUsersOrGroups];
}



- (void) didSelectCloseView {
    
    [self dismissViewControllerAnimated:true completion:nil];
}

//- (void) sharedLinkSwithValueChanged: (UISwitch*)sender {
//    
//    if (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && APP_DELEGATE.activeUser.capabilitiesDto) {
//        OCCapabilities *cap = APP_DELEGATE.activeUser.capabilitiesDto;
//        
//        if (!cap.isFilesSharingShareLinkEnabled) {
//            sender.on = false;
//            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"not_share_link_enabled_capabilities", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
//            [alertView show];
//            return;
//        }
//    }
//
//        [self getShareLinkView];
//        [self unShareByLink];
//
//}





#pragma mark - Actions with ShareFileOrFolder class

- (void) getShareLinkView {
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    if (IS_IPHONE) {
        self.sharedFileOrFolder.viewToShow = self.view;
        self.sharedFileOrFolder.parentViewController = self;
    }else{
        self.sharedFileOrFolder.viewToShow = self.view;
        self.sharedFileOrFolder.parentViewController = self;
        self.sharedFileOrFolder.parentView = self.view;
    }
    
    if (self.sharedItem.sharedFileSource > 0){
        self.sharedFileOrFolder.file = self.sharedItem;
        [self.sharedFileOrFolder clickOnShareLinkFromFileDto:true];
    }else{
        [self.sharedFileOrFolder showShareActionSheetForFile:self.sharedItem];
    }
}

- (void) unShareByIdRemoteShared:(NSInteger) idRemoteShared{
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    self.sharedFileOrFolder.parentViewController = self;
    
    [self.sharedFileOrFolder unshareTheFileByIdRemoteShared:idRemoteShared];
}


- (void) checkSharedStatusOFile {
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    self.sharedFileOrFolder.parentViewController = self;
    
    self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
    
    [self.sharedFileOrFolder checkSharedStatusOfFile:self.sharedItem];
    
}

#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    return YES;
}

#pragma mark - UIAlertView delegate methods


- (void) alertView: (UIAlertView *) alertView willDismissWithButtonIndex: (NSInteger) buttonIndex
{
    
    if( buttonIndex == 1 ){
        //Update share item with password
        
        NSString* password = [alertView textFieldAtIndex:0].text;
        [self initLoading];
       // [self updateSharedLinkWithPassword:password expirationDate:nil permissions:k_permissions_do_not_update];
        
    }else if (buttonIndex == 0) {
        //Cancel
        [self reloadView];
        
    }else {
        //Nothing
    }

}


- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    BOOL output = YES;
    if (alertView.tag == password_alert_view_tag) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        if ([textField.text length] == 0){
            output = NO;
        }
    }

    return output;
}


#pragma mark - TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    NSInteger numberOfSections = shareTableViewSectionsNumber;
    
    if (!k_is_share_with_users_available) {
        numberOfSections--;
    }
    
    if (!k_is_share_by_link_available) {
        numberOfSections--;
    }
    
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 1;
    }else if (section == 1 && k_is_share_with_users_available){
        if (self.sharedUsersOrGroups.count == 0) {
           return 1;
        }else{
           return self.sharedUsersOrGroups.count;
        }
    } else if ((section == 1 || section == 2) && k_is_share_by_link_available){
        //TODO: check where init sharedpubliclinks
        if (self.sharedPublicLinks.count == 0) {
            return 1;
        }else{
            return self.sharedPublicLinks.count;
        }
    } else {
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    switch (indexPath.section) {
        case 0:
            
            cell = [self getCellOfFileOrFolderInformationByTableView:tableView];
            
            break;
        case 1:
            
            //All available
            if (k_is_share_with_users_available) {
                
                cell = [self getCellOfUserOrGroupNameSharedByTableView:tableView andIndexPath:indexPath];
              
            } else if (k_is_share_by_link_available) {
               
                cell = [self getCellShareLinkByTableView:tableView andIndexPath:indexPath];
            }
            break;
            
        case 2:
            cell = [self getCellShareLinkByTableView:tableView andIndexPath:indexPath];

            break;
        default:
            break;
    }
    
    return cell;
    
}

#pragma mark - Cells

- (UITableViewCell *) getCellOfFileOrFolderInformationByTableView:(UITableView *) tableView {
    
    ShareFileCell* shareFileCell = (ShareFileCell*)[tableView dequeueReusableCellWithIdentifier:shareFileCellIdentifier];
    
    if (shareFileCell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareFileCellNib owner:self options:nil];
        shareFileCell = (ShareFileCell *)[topLevelObjects objectAtIndex:0];
    }
    
    NSString *itemName = [self.sharedItem.fileName stringByRemovingPercentEncoding];
    
    shareFileCell.fileName.hidden = self.sharedItem.isDirectory;
    shareFileCell.fileSize.hidden = self.sharedItem.isDirectory;
    shareFileCell.folderName.hidden = !self.sharedItem.isDirectory;
    
    if (self.sharedItem.isDirectory) {
        shareFileCell.fileImage.image = [UIImage imageNamed:@"folder_icon"];
        shareFileCell.folderName.text = @"";
        //Remove the last character (folderName/ -> folderName)
        shareFileCell.folderName.text = [itemName substringToIndex:[itemName length]-1];
        
    }else{
        shareFileCell.fileImage.image = [UIImage imageNamed:[FileNameUtils getTheNameOfTheImagePreviewOfFileName:[self.sharedItem.fileName stringByRemovingPercentEncoding]]];
        shareFileCell.fileSize.text = [NSByteCountFormatter stringFromByteCount:[NSNumber numberWithLong:self.sharedItem.size].longLongValue countStyle:NSByteCountFormatterCountStyleMemory];
        shareFileCell.fileName.text = itemName;
    }
    
    return shareFileCell;
    
}


- (UITableViewCell *) getCellShareLinkByTableView:(UITableView *)tableView andIndexPath:(NSIndexPath *)indexPath {
    
    ShareMainLinkCell* shareLinkCell = (ShareMainLinkCell*)[tableView dequeueReusableCellWithIdentifier:shareMainLinkCellIdentifier];
    
    if (shareLinkCell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareUserCellNib owner:self options:nil];
        shareLinkCell = (ShareMainLinkCell *)[topLevelObjects objectAtIndex:0];
    }
    
    if (self.sharedPublicLinks.count == 0) {
        NSString *name = NSLocalizedString(@"not_share_by_link_yet", nil);
    
        shareLinkCell.itemName.text = name;
        shareLinkCell.itemName.textColor = [UIColor grayColor];
    
    } else {
       //TODO: set with object link
        OCSharedDto *shareLink = [self.sharedPublicLinks objectAtIndex:indexPath.row];
        
        shareLinkCell.itemName.text = ([shareLink.name length] == 0 ) ? shareLink.token: shareLink.name;
;
        shareLinkCell.accessoryType = UITableViewCellAccessoryDetailButton;
    }
    
    shareLinkCell.selectionStyle = UITableViewCellEditingStyleNone;
    
    return shareLinkCell;
}

- (UITableViewCell *) getCellOfUserOrGroupNameSharedByTableView:(UITableView *) tableView andIndexPath:(NSIndexPath *) indexPath {
    
    ShareUserCell* shareUserCell = (ShareUserCell*)[tableView dequeueReusableCellWithIdentifier:shareUserCellIdentifier];
    
    if (shareUserCell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareUserCellNib owner:self options:nil];
        shareUserCell = (ShareUserCell *)[topLevelObjects objectAtIndex:0];
    }
    
    NSString *name;
    
    if (self.sharedUsersOrGroups.count == 0) {
        
        name = NSLocalizedString(@"not_share_with_users_yet", nil);
        
        shareUserCell.itemName.textColor = [UIColor grayColor];
        
    } else {
        
        OCShareUser *shareUser = [self.sharedUsersOrGroups objectAtIndex:indexPath.row];
        
        if (shareUser.shareeType == shareTypeGroup) {
            name = [NSString stringWithFormat:@"%@ (%@)",shareUser.name, NSLocalizedString(@"share_user_group_indicator", nil)];
            
        } else {
            
            if (shareUser.isDisplayNameDuplicated) {
                name = [NSString stringWithFormat:@"%@ (%@)", shareUser.displayName, shareUser.name];
            }else{
                name = shareUser.displayName;
            }
        }
        
        shareUserCell.accessoryType = UITableViewCellAccessoryDetailButton;
    }
    
    shareUserCell.itemName.text = name;
    shareUserCell.selectionStyle = UITableViewCellEditingStyleNone;
    
    return shareUserCell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = 0.0;
    
    switch (indexPath.section) {
        case 0:
            height = heighOfFileDetailrow;
            break;
        case 1:
            if (k_is_share_with_users_available) {
                
                height = heightOfShareWithUserRow;
                
            } else {

                height = heightOfShareMainLinkRow;
            }
            break;
        case 2:
            height = heightOfShareMainLinkRow;
            break;
            
        default:
            break;
    }
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat height = 10.0;
    
    if (section == 1 || section == 2) {
        height = heightOfShareLinkHeader;
    }
    
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.shareTableView.frame.size.width, 1)];
    
    
    if (section == 1 || section == 2) {
        
        ShareLinkHeaderCell* shareLinkHeaderCell = [tableView dequeueReusableCellWithIdentifier:shareLinkHeaderIdentifier];
        
        if (shareLinkHeaderCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkHeaderNib owner:self options:nil];
            shareLinkHeaderCell = (ShareLinkHeaderCell *)[topLevelObjects objectAtIndex:0];
        }
        
        switch (section) {
            case 1:
                if (k_is_share_with_users_available) {
                    shareLinkHeaderCell = [self getHeaderCellForShareWithUsersOrGroups:shareLinkHeaderCell];
                } else if (!k_is_share_with_users_available && k_is_share_by_link_available){
                    shareLinkHeaderCell = [self getHeaderCellForShareByLink:shareLinkHeaderCell];
                }
                break;
            case 2:
                if (k_is_share_by_link_available){
                    shareLinkHeaderCell = [self getHeaderCellForShareByLink:shareLinkHeaderCell];
                }
                break;
                
            default:
                break;
        }
        
        headerView = shareLinkHeaderCell.contentView;
        
    }
    
    return headerView;
}

/*
 * Method to get the header for the first section: Share with user or groups
 */
- (ShareLinkHeaderCell *) getHeaderCellForShareWithUsersOrGroups:(ShareLinkHeaderCell *) shareLinkHeaderCell {
    
    shareLinkHeaderCell.titleSection.text = NSLocalizedString(@"share_with_users_or_groups", nil);
    shareLinkHeaderCell.switchSection.hidden = true;
    shareLinkHeaderCell.addButtonSection.hidden = false;
    
    [shareLinkHeaderCell.addButtonSection addTarget:self action:@selector(didSelectAddUserOrGroup) forControlEvents:UIControlEventTouchUpInside];
    
    return shareLinkHeaderCell;
}

/*
 * Method to get the header for the second section: Share by link
 */
- (ShareLinkHeaderCell *) getHeaderCellForShareByLink:(ShareLinkHeaderCell *) shareLinkHeaderCell {
    
    shareLinkHeaderCell.titleSection.text = NSLocalizedString(@"share_link_title", nil);
    shareLinkHeaderCell.switchSection.hidden = true;
    shareLinkHeaderCell.addButtonSection.hidden = false;
    
    [shareLinkHeaderCell.addButtonSection addTarget:self action:@selector(didSelectAddUserOrGroup) forControlEvents:UIControlEventTouchUpInside];
    
    return shareLinkHeaderCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    switch (indexPath.section) {
        case 1:
            if (k_is_share_with_users_available) {
                [self didSelectAddUserOrGroup];
            } else if(k_is_share_by_link_available) {
                [self didSelectAddPublicLink];
            }
            
            break;
        case 2:
            [self didSelectAddPublicLink];
            break;
        default:
            break;
    }
}

//- (void) didSelectShareLinkOptionSection:(NSInteger) row {
//    switch (row) {
//        case 0:
//            if (self.isExpirationDateEnabled) {
//                [self didSelectSetExpirationDateLink];
//            }
//            break;
//        case 1:
//            if (self.isPasswordProtectEnabled) {
//                [self didSelectSetPasswordLink];
//            }
//            break;
//        default:
//            break;
//    }
//}

- (void) didSelectAddUserOrGroup {
    //Check if the server has Sharee support
    if (APP_DELEGATE.activeUser.hasShareeApiSupport == serverFunctionalitySupported) {
        ShareSearchUserViewController *ssuvc = [[ShareSearchUserViewController alloc] initWithNibName:@"ShareSearchUserViewController" bundle:nil];
        ssuvc.shareFileDto = self.sharedItem;
        [ssuvc setAndAddSelectedItems:self.sharedUsersOrGroups];
        self.activityView = nil;
        [self.navigationController pushViewController:ssuvc animated:NO];
    }else{
        [self showErrorWithTitle:NSLocalizedString(@"not_sharee_api_supported", nil)];
        
    }
}

- (void) didSelectAddPublicLink {
    //Check if the server has Sharee support
    if (APP_DELEGATE.activeUser.hasShareeApiSupport == serverFunctionalitySupported) {
        ShareSearchUserViewController *ssuvc = [[ShareSearchUserViewController alloc] initWithNibName:@"ShareSearchUserViewController" bundle:nil];
        ssuvc.shareFileDto = self.sharedItem;
        [ssuvc setAndAddSelectedItems:self.sharedUsersOrGroups];
        self.activityView = nil;
        [self.navigationController pushViewController:ssuvc animated:NO];
    }
}

- (void) didSelectGetShareLink {
    [self getShareLinkView];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    switch (indexPath.section) {
        case 0:
            return NO;
            break;
        case 1:
            if (k_is_share_with_users_available && self.sharedUsersOrGroups.count > 0) {
                return YES;
            } else if (k_is_share_by_link_available && self.sharedPublicLinks.count > 0){
                return YES;
            } else {
                return NO;
            }
            break;
        case 2:
            if (k_is_share_by_link_available && self.sharedPublicLinks.count > 0) {
                return YES;
            } else {
                return NO;
            }
            break;
        default:
            return NO;
            break;
    }
}



- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        
        if (k_is_share_with_users_available && indexPath.section == 1) {
           
            OCShareUser *sharedUser = [self.sharedUsersOrGroups objectAtIndex:indexPath.row];
            [self unShareByIdRemoteShared: sharedUser.sharedDto.idRemoteShared];

        } else {
            
            OCSharedDto *sharedItem = [self.sharedPublicLinks objectAtIndex:indexPath.row];
            [self unShareByIdRemoteShared: sharedItem.idRemoteShared];
        }
        
    }
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    
    
    if (k_is_share_with_users_available && indexPath.section == 1) {
        //Edit share with user Privileges
        
        OCShareUser *shareUser = [self.sharedUsersOrGroups objectAtIndex:indexPath.row];
        OCSharedDto *shareDto = shareUser.sharedDto;
        
        ShareEditUserViewController *viewController = [[ShareEditUserViewController alloc] initWithFileDto:self.sharedItem andOCSharedDto:shareDto];
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        
        if (IS_IPHONE)
        {
            viewController.hidesBottomBarWhenPushed = YES;
            [self presentViewController:navController animated:YES completion:nil];
        } else {
            OCNavigationController *navController = nil;
            navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:navController animated:YES completion:nil];
        }
        
    } else if (k_is_share_by_link_available) {
        //TODO: edit link options
        
        OCSharedDto *shareDto = [self.sharedPublicLinks objectAtIndex:indexPath.row];
        
        ShareLinkViewController *viewController = [[ShareLinkViewController alloc] initWithFileDto:self.sharedItem andOCSharedDto:shareDto andLinkOptionsViewMode:LinkOptionsViewModeEdit];
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        
        if (IS_IPHONE)
        {
            viewController.hidesBottomBarWhenPushed = YES;
            [self presentViewController:navController animated:YES completion:nil];
        } else {
            OCNavigationController *navController = nil;
            navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:navController animated:YES completion:nil];
        }

        
    }

    
}


#pragma mark - ShareFileOrFolder Delegate Methods

- (void) initLoading {

    if (self.loadingView == nil) {
        self.loadingView = [[MBProgressHUD alloc]initWithWindow:[UIApplication sharedApplication].keyWindow];
        self.loadingView.delegate = self;
    }
        
    [self.view addSubview:self.loadingView];
    
    self.loadingView.labelText = NSLocalizedString(@"loading", nil);
    self.loadingView.dimBackground = false;
    
    [self.loadingView show:true];
    
    self.view.userInteractionEnabled = false;
    self.navigationController.navigationBar.userInteractionEnabled = false;
    self.view.window.userInteractionEnabled = false;

}

- (void) endLoading {
    
    if (!APP_DELEGATE.isLoadingVisible) {
        [self.loadingView removeFromSuperview];
        
        self.view.userInteractionEnabled = true;
        self.navigationController.navigationBar.userInteractionEnabled = true;
        self.view.window.userInteractionEnabled = true;
        
    }
}

- (void) errorLogin {
    
     [self endLoading];
    
     [self performSelector:@selector(showEditAccount) withObject:nil afterDelay:animationsDelay];
    
     [self performSelector:@selector(showErrorAccount) withObject:nil afterDelay:largeDelay];
   
}

- (void) finishShareWithStatus:(BOOL)successful andWithOptions:(UIActivityViewController*) activityView{
    
    if (successful) {
         self.activityView = activityView;
         [self checkSharedStatusOFile];
        
    }else{
       [self performSelector:@selector(updateInterfaceWithShareLinkStatus) withObject:nil afterDelay:standardDelay];

    }
}

- (void) finishUnShareWithStatus:(BOOL)successful {
    
    if (successful) {
        self.activityView = nil;
        [self checkSharedStatusOFile];
    }else{
        [self performSelector:@selector(updateInterfaceWithShareLinkStatus) withObject:nil afterDelay:standardDelay];
    }
    
}

- (void) finishUpdateShareWithStatus:(BOOL)successful {
    
    [self performSelector:@selector(updateInterfaceWithShareLinkStatus) withObject:nil afterDelay:standardDelay];
    
}

- (void) finishCheckSharedStatusOfFile:(BOOL)successful {
    
    if (successful && self.activityView != nil) {
        [self updateInterfaceWithShareLinkStatus];
        [self performSelector:@selector(presentShareOptions) withObject:nil afterDelay:standardDelay];
    }else{
        [self performSelector:@selector(updateInterfaceWithShareLinkStatus) withObject:nil afterDelay:standardDelay];
    }

}


- (void) presentShareOptions{
    
    
    NSString *fileOrFolderName = self.sharedItem.fileName;
    if(self.sharedItem.isDirectory){
        //Remove the last character (folderName/ -> folderName)
        fileOrFolderName = [fileOrFolderName substringToIndex:fileOrFolderName.length -1];
    }
    
    NSString *subject = [[NSLocalizedString(@"shared_link_mail_subject", nil)stringByReplacingOccurrencesOfString:@"$userName" withString:[ManageUsersDB getActiveUser].username]stringByReplacingOccurrencesOfString:@"$fileOrFolderName"  withString:[fileOrFolderName stringByRemovingPercentEncoding]];
    [self.activityView setValue:subject forKey:k_subject_key_activityView];
    
    if (IS_IPHONE) {
        [self presentViewController:self.activityView animated:true completion:nil];
        [self performSelector:@selector(reloadView) withObject:nil afterDelay:standardDelay];
    }else{
        [self reloadView];
        
        self.activityPopoverController = [[UIPopoverController alloc]initWithContentViewController:self.activityView];
        
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:2 inSection:1];
        UITableViewCell* cell = [self.shareTableView cellForRowAtIndexPath:indexPath];
        
        [self.activityPopoverController presentPopoverFromRect:cell.frame inView:self.shareTableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:true];
    }
}

#pragma mark - Error Login Methods

- (void) showEditAccount {
    
#ifdef CONTAINER_APP
    
    //Edit Account
    self.resolveCredentialErrorViewController = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:[ManageUsersDB getActiveUser]];
    [self.resolveCredentialErrorViewController setBarForCancelForLoadingFromModal];
    
    if (IS_IPHONE) {
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:self.resolveCredentialErrorViewController];
        [self.navigationController presentViewController:navController animated:YES completion:nil];
        
    } else {
        
        OCNavigationController *navController = nil;
        navController = [[OCNavigationController alloc] initWithRootViewController:self.resolveCredentialErrorViewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    }
    
#endif
    
}

- (void) showErrorAccount {
    
    if (k_is_sso_active) {
        [self showErrorWithTitle:NSLocalizedString(@"session_expired", nil)];
    }else{
        [self showErrorWithTitle:NSLocalizedString(@"error_login_message", nil)];
    }
    
}

- (void)showErrorWithTitle: (NSString *)title {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [alertView show];
    
    
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

@end
