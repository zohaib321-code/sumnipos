---
name: Kinetic POS
colors:
  surface: '#faf8ff'
  surface-dim: '#d8d9e6'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#ecedfa'
  surface-container-high: '#e6e7f4'
  surface-container-highest: '#e1e2ee'
  on-surface: '#191b24'
  on-surface-variant: '#424656'
  inverse-surface: '#2e303a'
  inverse-on-surface: '#eff0fd'
  outline: '#727687'
  outline-variant: '#c2c6d8'
  surface-tint: '#0054d6'
  primary: '#0050cb'
  on-primary: '#ffffff'
  primary-container: '#0066ff'
  on-primary-container: '#f8f7ff'
  inverse-primary: '#b3c5ff'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#a33200'
  on-tertiary: '#ffffff'
  tertiary-container: '#cc4204'
  on-tertiary-container: '#fff6f4'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae1ff'
  primary-fixed-dim: '#b3c5ff'
  on-primary-fixed: '#001849'
  on-primary-fixed-variant: '#003fa4'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffdbd0'
  tertiary-fixed-dim: '#ffb59d'
  on-tertiary-fixed: '#390c00'
  on-tertiary-fixed-variant: '#832600'
  background: '#faf8ff'
  on-background: '#191b24'
  surface-variant: '#e1e2ee'
typography:
  display:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.1'
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: '1.2'
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.2'
  body-lg:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '500'
    lineHeight: '1.5'
  body-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.5'
  label-xl:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '700'
    lineHeight: '1.0'
    letterSpacing: 0.02em
  numeral-lg:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '700'
    lineHeight: '1.0'
spacing:
  touch-target-min: 80px
  gutter: 12px
  margin-screen: 24px
  stack-gap: 16px
  tile-padding: 20px
---

## Brand & Style

The design system is engineered for high-volume retail and hospitality environments where speed of service is the primary metric of success. The brand personality is utilitarian, dependable, and invisible—it stays out of the way to let the operator work at peak efficiency. 

The aesthetic follows a **Minimalist** philosophy, stripping away all decorative elements like gradients and depth to reduce cognitive load. The emotional response is one of confidence and clarity; the user should never hesitate to find a button or read a price. By using a flat design language, we eliminate the visual "noise" often found in legacy POS systems, focusing entirely on functional speed and hit-area precision.

## Colors

The palette is anchored by a neutral "Studio Gray" background to prevent eye strain during long shifts. 

- **Primary Action:** A vibrant Professional Blue (#0066FF) is reserved strictly for primary path actions like "Pay" or "Confirm."
- **Secondary Action:** A Forest Green (#10B981) is used for additive actions or successful states.
- **Surface:** White (#FFFFFF) is used for active input tiles and the current order list to separate them from the system background.
- **Text:** An almost-black Zinc (#09090B) ensures maximum AAA accessibility and legibility under harsh overhead lighting.

## Typography

This design system utilizes **Inter** for its exceptional legibility and tabular numeric qualities, which are essential for price alignment.

Typography is intentionally oversized to accommodate standing distance from the screen. Headlines are tight and bold to create a clear hierarchy in the cart view. For price displays, use `numeral-lg` to ensure the total is the most prominent element on the screen. All labels are set with increased tracking to ensure readability at a glance.

## Layout & Spacing

The layout uses a **Fluid Grid** optimized for landscape touchscreen displays. The interface is split into a 2-column master layout: a 4-column-width "Order Sidebar" on the left (or right based on user preference) and an 8-column-width "Product Grid" in the main area.

Key constraints:
- **Margins:** A 24px safe zone around the screen perimeter prevents accidental edge touches.
- **The 80px Rule:** No interactive element (button, toggle, or list item) shall have a height or width smaller than 80px.
- **Rhythm:** Use a 4px baseline, with most component gaps defaulting to 16px to ensure distinct separation between touchable tiles.

## Elevation & Depth

This design system strictly avoids shadows to maintain a flat, performant aesthetic. Instead of depth, visual hierarchy is achieved through **Tonal Layering** and **High-Contrast Outlines**.

- **Level 0 (Background):** Light gray (#F4F4F5).
- **Level 1 (Interactive Tiles):** White (#FFFFFF) with a 2px solid border (#E4E4E7).
- **Level 2 (Active/Pressed):** The primary accent color or a darker neutral gray to indicate selection.
- **Focus:** When an item is selected in the cart, use a 4px solid primary color stroke inside the container rather than a shadow.

## Shapes

The design system utilizes **Sharp (0px)** corners for all primary UI elements. 

Rectangular tiles maximize the available screen real estate and align perfectly with the grid, reinforcing the sense of stability and precision. The lack of border-radius allows tiles to sit flush against one another in button groups, creating clear, unified control blocks for quantity adjustments and category switching.

## Components

### Buttons & Action Bars
- **Action Buttons:** Large 80px minimum height. Primary actions use the primary accent color with white text.
- **Fixed-Bottom Bar:** The "Checkout" or "Total" button must be pinned to the bottom of the screen, spanning the full width of its container, ensuring it is always reachable by the thumb.

### Product Tiles
- **Flat Tiles:** Rectangular blocks with a 2px border. Text is top-aligned; prices are bottom-right aligned in a bold weight.
- **Visual Feedback:** On tap, the tile should instantly switch to a high-contrast inverted state (Dark background, Light text) for 100ms to confirm the touch.

### Quantity Controls
- **Step Controls:** Large "+" and "-" buttons flanking a central number. These must be at least 80x80px each to prevent "fat-finger" errors.
- **Input Fields:** Large, flat white boxes with 2px borders. On tap, they trigger a full-screen or large-scale numeric keypad overlay rather than a standard system keyboard.

### Lists
- **Cart Items:** Each row is 80px tall. Use a "swipe-to-delete" gesture or a large, dedicated "X" button on the far right of the row.

### Category Tabs
- **Top Navigation:** Large rectangular tabs positioned at the top of the product grid. Active tabs are indicated by a 6px bottom-border in the primary accent color.