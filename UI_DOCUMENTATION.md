# UI Flow Documentation

## Screen Flow

```
┌─────────────────────────────────────┐
│    AuthenticationView (Landing)     │
│                                     │
│  ┌───────────────────────────────┐ │
│  │   [App Logo/Icon]             │ │
│  │   Anonymous Wall              │ │
│  │   Your Voice, Your Community  │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │     [Get Started Button]      │ │ ──────┐
│  └───────────────────────────────┘ │       │
│                                     │       │
│  ┌───────────────────────────────┐ │       │
│  │     [Login Button]            │ │ ──┐   │
│  └───────────────────────────────┘ │   │   │
└─────────────────────────────────────┘   │   │
                                          │   │
                 ┌────────────────────────┘   │
                 │                            │
                 ▼                            ▼
┌─────────────────────────────────┐ ┌─────────────────────────────────┐
│       LoginView                 │ │     RegistrationView            │
│                                 │ │                                 │
│  ┌───────────────────────────┐ │ │  ┌───────────────────────────┐ │
│  │ [Lock Icon]               │ │ │  │ [Person Icon]             │ │
│  │ Welcome Back              │ │ │  │ Create Account            │ │
│  └───────────────────────────┘ │ │  └───────────────────────────┘ │
│                                 │ │                                 │
│  Email: [________________]      │ │  Email: [________________]      │
│         [Get Code]              │ │                                 │
│                                 │ │  ┌───────────────────────────┐ │
│  Verification Code:             │ │  │  [Send Verification Code] │ │
│         [______]                │ │  └───────────────────────────┘ │
│                                 │ │                                 │
│  ┌───────────────────────────┐ │ │  Don't have an account?         │
│  │       [Login Button]      │ │ │  [Login] ──────────────────┐    │
│  └───────────────────────────┘ │ │                            │    │
│                                 │ └────────────────────────────┼────┘
│  Don't have an account?         │                              │
│  [Sign Up] ─────────────────────┼──────────────────────────────┘
└─────────────────────────────────┘
                 │
                 │ (After successful login)
                 ▼
┌─────────────────────────────────────┐
│           WallView                  │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ Welcome to Anonymous Wall!    │ │
│  │                               │ │
│  │ Logged in as: user@email.com  │ │
│  └───────────────────────────────┘ │
│                                     │
│  Post Feed Coming Soon...           │
│                                     │
│  ┌───────────────────────────────┐ │
│  │     [Logout Button]           │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

## UI Components Details

### 1. AuthenticationView (Landing Screen)
- **App Logo**: Bubble chat icon in blue
- **App Title**: "Anonymous Wall" in large bold text
- **Tagline**: "Your Voice, Your Community"
- **Get Started Button**: Blue button, leads to RegistrationView
- **Login Button**: White button with blue border, leads to LoginView

### 2. RegistrationView
- **Header**: Person icon + "Create Account" title
- **Email Field**: Text input for email address
  - Auto-capitalization disabled
  - Email keyboard type
  - Validation for email format
- **Send Button**: Blue button to send verification code
  - Disabled when email is empty
  - Shows loading indicator when processing
- **Success Alert**: Confirmation that code was sent
- **Navigation**: Link to LoginView for existing users

### 3. LoginView
- **Header**: Lock icon + "Welcome Back" title
- **Email Field**: Text input with "Get Code" button
  - Same validation as registration
  - Button to request new verification code
- **Verification Code Field**: Numeric input for 6-digit code
  - Number pad keyboard
- **Status Messages**:
  - Success (green): "Verification code sent to your email!"
  - Error (red): API error messages
- **Login Button**: Blue button to authenticate
  - Disabled until both fields are filled
  - Shows loading indicator when processing
- **Navigation**: Link to RegistrationView for new users

### 4. WallView (Post Authentication)
- **Welcome Message**: Personalized with user's email
- **Placeholder**: "Post Feed Coming Soon..."
- **Logout Button**: Red button to end session

## Color Scheme
- **Primary**: Blue (system blue)
- **Success**: Green
- **Error**: Red
- **Background**: System background (white/black based on dark mode)
- **Input Fields**: Light gray background (systemGray6)

## Typography
- **Large Title**: 36pt bold for app name
- **Title**: System large title for screen headers
- **Headline**: For field labels
- **Subheadline**: For descriptive text
- **Body**: For normal content

## Interactive Elements
- All buttons have rounded corners (10pt radius)
- Disabled states show gray color
- Loading states show circular progress indicators
- Input fields have light gray backgrounds
- Error messages appear below relevant fields

## Navigation
- Uses SwiftUI NavigationStack
- NavigationLink for view transitions
- Programmatic navigation for post-authentication flow
- Back navigation available on all sub-views

## Navigation Improvements (Latest Updates)

### RegistrationView Navigation
- **Navigation Bar**: Now visible with title "Create Account"
- **Back Button**: Automatically provided by NavigationStack
- **User Action**: Tap "< Back" or swipe right to return to AuthenticationView

### WallView Menu System
- **Hamburger Menu**: Three horizontal lines icon (☰) in top right
- **Menu Items**:
  - **Change Password** (conditional): Only shown if password is already set
    - Icon: Lock shield (🔒)
    - Action: Opens ChangePasswordView sheet
  - **Logout** (always shown):
    - Icon: Rectangle with arrow (🚪)
    - Style: Destructive (red text)
    - Action: Logs out user and returns to AuthenticationView

### Benefits of Menu System
1. **More Screen Space**: Removed large buttons from bottom of WallView
2. **Professional UI**: Standard iOS hamburger menu pattern
3. **Organized Settings**: All account actions in one place
4. **Scalable**: Easy to add more menu items in future
5. **Clear Hierarchy**: Destructive actions (logout) properly styled

### Before vs After

**Before (RegistrationView)**:
- No navigation bar → User stuck, can't go back
- Had to restart app to exit registration flow

**After (RegistrationView)**:
- Navigation bar with back button
- Can easily return to main screen
- Standard iOS navigation pattern

**Before (WallView)**:
- Large "Change Password" button (if password set)
- Large red "Logout" button at bottom
- Takes significant screen space

**After (WallView)**:
- Clean interface with hamburger menu
- Settings tucked away but easily accessible
- More space for future content (post feed)
