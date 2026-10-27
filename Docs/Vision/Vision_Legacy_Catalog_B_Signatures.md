# Vision Framework — Legacy API Catalog (Option B: Signatures)

This is a REFERENCE CATALOG of the legacy Vision API (VN* classes, completion-handler
style, iOS 11+), NOT full documentation. It lists every legacy document that was
scraped (902 total), so you can tell what exists and pick the right symbol.

Entry format:  id [kind] `declaration` — description
  - id      document id; all ids are under the Vision framework
  - [kind]  symbol kind, plus status markers when they apply:
              deprecated                 Apple has deprecated this symbol
              deprecated (renamed: X)    deprecated; X is Apple's named replacement
              beta                       marked beta
            No marker means the symbol is NOT deprecated. When suggesting code, prefer the
            "renamed" replacement over a deprecated symbol.
  - `…`     Swift declaration
  - — …     Apple's one-line description (may be absent)

A type is followed by its members; blank lines separate top-level symbols.

TO GET THE FULL DOCUMENTATION for any entry, ask the user for it by id, e.g.
"please provide vision/vnrecognizetextrequest/recognitionlevel". The user retrieves
it with:  node get-doc.js <id>

Generated: 2026-10-12T02:03:54.795Z
────────────────────────────────────────────────────────────────────────────────

vision [Framework] — Analyze image and video content in your app using computer vision algorithms for object detection, text recognition, and image segmentation.

vision/aligning-similar-images [Sample Code] — Construct a composite image from images that capture the same scene.

vision/analyzing-image-similarity-with-feature-print [Sample Code] — Generate a feature print to compute distance between images.

vision/applying-matte-effects-to-people-in-images-and-video [Sample Code] — Generate image masks for people automatically by using semantic person-segmentation.

vision/applying-visual-effects-to-foreground-subjects [Sample Code] — Segment the foreground subjects of an image and composite them to a new background with visual effects.

vision/body-landmarks [API Collection] — The body landmarks that Vision detects.

vision/building-a-feature-rich-app-for-sports-analysis [Sample Code] — Detect and classify human activity in real time using computer vision and machine learning.

vision/classifying-images-for-categorization-and-search [Sample Code] — Analyze and label images using a Vision classification request.

coreml/classifying-images-with-vision-and-core-ml [Sample Code] — Crop and scale photos using the Vision framework and classify them with a Core ML model.

vision/cropping-images-using-saliency [Article] — Isolate regions in an image that are most likely to draw people’s attention.

vision/detecting-animal-body-poses-with-vision [Sample Code] — Draw the skeleton of an animal by using Vision’s capability to detect animal body poses.

vision/detecting-hand-poses-with-vision [Sample Code] — Create a virtual drawing app by using Vision’s capability to detect hand poses.

createml/detecting-human-actions-in-a-live-video-feed [Sample Code] — Identify body movements by sending a person’s pose data from a series of video frames to an action-classification model.

vision/detecting-human-body-poses-in-3d-with-vision [Sample Code] — Render skeletons of 3D body pose points in a scene overlaying the input image.

vision/detecting-human-body-poses-in-images [Article] — Add the capability to detect human body poses to your app using the Vision framework.

vision/detecting-moving-objects-in-a-video [Sample Code] — Identify the trajectory of a thrown object by using Vision.

vision/detecting-objects-in-still-images [Sample Code] — Locate and demarcate rectangles, faces, barcodes, and text in images using the Vision framework.

vision/extracting-phone-numbers-from-text-in-images [Sample Code] — Analyze and filter phone numbers from text in live capture by using Vision.

vision/hand-landmarks [API Collection] — The hand landmarks that Vision detects.

vision/highlighting-areas-of-interest-in-an-image-using-saliency [Sample Code] — Quantify and visualize where people are likely to look in an image.

vision/identifying-3d-human-body-poses-in-images [Article] — Detect three-dimensional human body poses using the Vision framework.

vision/identifying-trajectories-in-video [Article] — Gain new insights into your video data by using Vision to detect trajectories.

vision/locating-and-displaying-recognized-text [Sample Code] — Perform text recognition on a photo using the Vision framework’s text-recognition request.

vision/original-objective-c-and-swift-api [API Collection]

vision/recognizing-objects-in-live-capture [Sample Code] — Apply Vision algorithms to identify objects in real-time video.

vision/recognizing-text-in-images [Article] — Add text-recognition features to your app using the Vision framework.

vision/segmenting-and-colorizing-individuals-from-a-surrounding-scene [Sample Code] — Use the Vision framework to isolate and apply colors to people in an image.

vision/selecting-a-selfie-based-on-capture-quality [Sample Code] — Compare face-capture quality in a set of images by using Vision.

visionkit/structuring-recognized-text-on-a-document [Sample Code] — Detect, recognize, and structure text on a business card or receipt using Vision and VisionKit.

vision/tracking-multiple-objects-or-rectangles-in-video [Sample Code] — Apply Vision algorithms to track objects or rectangles throughout a video.

vision/tracking-the-user-s-face-in-real-time [Sample Code] — Detect and track faces from the selfie cam feed in real time.

vision/training-a-create-ml-model-to-classify-flowers [Sample Code] — Train a flower classifier using Create ML in Swift Playgrounds, and apply the resulting model to real-time image classification using Vision.

coreml/understanding-a-dice-roll-with-vision-and-object-detection [Sample Code] — Detect dice position and values shown in a camera frame, and determine the end of a roll by leveraging a dice detection model.

vision/vision-macros [API Collection]

vision/vnanimalbodyposeobservation [Class] `class VNAnimalBodyPoseObservation` — An observation that provides the animal body points the analysis recognizes.
vision/vnanimalbodyposeobservation/availablejointgroupnames [Instance Property] `var availableJointGroupNames: [VNAnimalBodyPoseObservation.JointsGroupName] { get }` — The available joint group names in the observation.
vision/vnanimalbodyposeobservation/availablejointnames [Instance Property] `var availableJointNames: [VNAnimalBodyPoseObservation.JointName] { get }` — The names of the available joints in the observation.
vision/vnanimalbodyposeobservation/jointname [Structure] `struct JointName` — The joint names for an animal body pose.
vision/vnanimalbodyposeobservation/jointname/init(rawvalue:) [Initializer] `init(rawValue: VNRecognizedPointKey)` — Creates a joint name with the key you specify.
vision/vnanimalbodyposeobservation/jointname/leftbackelbow [Type Property] `static let leftBackElbow: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the back of the left elbow.
vision/vnanimalbodyposeobservation/jointname/leftbackknee [Type Property] `static let leftBackKnee: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the back of the left knee.
vision/vnanimalbodyposeobservation/jointname/leftbackpaw [Type Property] `static let leftBackPaw: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the back of the left paw.
vision/vnanimalbodyposeobservation/jointname/leftearbottom [Type Property] `static let leftEarBottom: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the bottom of the left ear.
vision/vnanimalbodyposeobservation/jointname/leftearmiddle [Type Property] `static let leftEarMiddle: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the middle of the left ear.
vision/vnanimalbodyposeobservation/jointname/lefteartop [Type Property] `static let leftEarTop: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the top of the left ear.
vision/vnanimalbodyposeobservation/jointname/lefteye [Type Property] `static let leftEye: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the left eye.
vision/vnanimalbodyposeobservation/jointname/leftfrontelbow [Type Property] `static let leftFrontElbow: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the front of the left elbow.
vision/vnanimalbodyposeobservation/jointname/leftfrontknee [Type Property] `static let leftFrontKnee: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the front of the left knee.
vision/vnanimalbodyposeobservation/jointname/leftfrontpaw [Type Property] `static let leftFrontPaw: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the front of the left paw.
vision/vnanimalbodyposeobservation/jointname/neck [Type Property] `static let neck: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the neck.
vision/vnanimalbodyposeobservation/jointname/nose [Type Property] `static let nose: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the nose.
vision/vnanimalbodyposeobservation/jointname/rightbackelbow [Type Property] `static let rightBackElbow: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the back of the right elbow.
vision/vnanimalbodyposeobservation/jointname/rightbackknee [Type Property] `static let rightBackKnee: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the back of the right knee.
vision/vnanimalbodyposeobservation/jointname/rightbackpaw [Type Property] `static let rightBackPaw: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the back of the right paw.
vision/vnanimalbodyposeobservation/jointname/rightearbottom [Type Property] `static let rightEarBottom: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the bottom of the right ear.
vision/vnanimalbodyposeobservation/jointname/rightearmiddle [Type Property] `static let rightEarMiddle: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the middle of the right ear.
vision/vnanimalbodyposeobservation/jointname/righteartop [Type Property] `static let rightEarTop: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the top of the right ear.
vision/vnanimalbodyposeobservation/jointname/righteye [Type Property] `static let rightEye: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the right eye.
vision/vnanimalbodyposeobservation/jointname/rightfrontelbow [Type Property] `static let rightFrontElbow: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the front of the right elbow.
vision/vnanimalbodyposeobservation/jointname/rightfrontknee [Type Property] `static let rightFrontKnee: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the front of the right knee.
vision/vnanimalbodyposeobservation/jointname/rightfrontpaw [Type Property] `static let rightFrontPaw: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the front of the right paw.
vision/vnanimalbodyposeobservation/jointname/tailbottom [Type Property] `static let tailBottom: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the bottom of the tail.
vision/vnanimalbodyposeobservation/jointname/tailmiddle [Type Property] `static let tailMiddle: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the middle of the tail.
vision/vnanimalbodyposeobservation/jointname/tailtop [Type Property] `static let tailTop: VNAnimalBodyPoseObservation.JointName` — A joint name that represents the top of the tail.
vision/vnanimalbodyposeobservation/jointsgroupname [Structure] `struct JointsGroupName` — The joint group names for an animal body pose.
vision/vnanimalbodyposeobservation/jointsgroupname/all [Type Property] `static let all: VNAnimalBodyPoseObservation.JointsGroupName` — A group name that represents all joints.
vision/vnanimalbodyposeobservation/jointsgroupname/forelegs [Type Property] `static let forelegs: VNAnimalBodyPoseObservation.JointsGroupName` — A group name that represents the forelegs.
vision/vnanimalbodyposeobservation/jointsgroupname/head [Type Property] `static let head: VNAnimalBodyPoseObservation.JointsGroupName` — A group name that represents the head.
vision/vnanimalbodyposeobservation/jointsgroupname/hindlegs [Type Property] `static let hindlegs: VNAnimalBodyPoseObservation.JointsGroupName` — A group name that represents the hindlegs.
vision/vnanimalbodyposeobservation/jointsgroupname/init(rawvalue:) [Initializer] `init(rawValue: VNRecognizedPointGroupKey)` — Creates a joint name with the key you specify.
vision/vnanimalbodyposeobservation/jointsgroupname/tail [Type Property] `static let tail: VNAnimalBodyPoseObservation.JointsGroupName` — A group name that represents the tail.
vision/vnanimalbodyposeobservation/jointsgroupname/trunk [Type Property] `static let trunk: VNAnimalBodyPoseObservation.JointsGroupName` — A group name that represents the trunk.
vision/vnanimalbodyposeobservation/recognizedpoint(_:) [Instance Method] `func recognizedPoint(_ jointName: VNAnimalBodyPoseObservation.JointName) throws -> VNRecognizedPoint` — Returns the point for a joint name the observation recognizes.
vision/vnanimalbodyposeobservation/recognizedpoints(_:) [Instance Method] `func recognizedPoints(_ jointsGroupName: VNAnimalBodyPoseObservation.JointsGroupName) throws -> [VNAnimalBodyPoseObservation.JointName : VNRecognizedPoint]` — Returns the points for a joint group name the observation recognizes.

vision/vnanimalidentifier [Structure] `struct VNAnimalIdentifier` — An animal identifier string.
vision/vnanimalidentifier/cat [Type Property] `static let cat: VNAnimalIdentifier` — An animal identifier for cats.
vision/vnanimalidentifier/dog [Type Property] `static let dog: VNAnimalIdentifier` — An animal identifier for dogs.
vision/vnanimalidentifier/init(rawvalue:) [Initializer] `init(rawValue: String)` — Creates an identifier with a string.

vision/vnaspectratio [Type Alias] `typealias VNAspectRatio = Float` — A type alias for expressing rectangle aspect ratios in Vision.

vision/vnbarcodecompositetype [Enumeration] `@frozen enum VNBarcodeCompositeType` — Composite types for barcode requests.
vision/vnbarcodecompositetype/gs1typea [Case] `case gs1TypeA` — A type that represents trade items in bulk.
vision/vnbarcodecompositetype/gs1typeb [Case] `case gs1TypeB` — A type that represents trade items by piece.
vision/vnbarcodecompositetype/gs1typec [Case] `case gs1TypeC` — A type that represents trade items in varying quantity.
vision/vnbarcodecompositetype/init(rawvalue:) [Initializer] `init?(rawValue: Int)`
vision/vnbarcodecompositetype/linked [Case] `case linked` — A type that represents a linked composite type.
vision/vnbarcodecompositetype/none [Case] `case none` — A type that represents no composite type.

vision/vnbarcodeobservation [Class] `class VNBarcodeObservation` — An object that represents barcode information that an image analysis request detects.
vision/vnbarcodeobservation/barcodedescriptor [Instance Property] `var barcodeDescriptor: CIBarcodeDescriptor? { get }` — An object that describes the low-level details about the barcode and its data.
vision/vnbarcodeobservation/iscolorinverted [Instance Property] `var isColorInverted: Bool { get }` — A Boolean value that indicates whether the barcode is color inverted.
vision/vnbarcodeobservation/isgs1datacarrier [Instance Property] `var isGS1DataCarrier: Bool { get }` — A Boolean value that indicates whether the barcode carries any global standards data.
vision/vnbarcodeobservation/payloaddata [Instance Property] `var payloadData: Data? { get }` — The raw data representation of the barcode’s payload.
vision/vnbarcodeobservation/payloadstringvalue [Instance Property] `var payloadStringValue: String? { get }` — A string value that represents the barcode payload.
vision/vnbarcodeobservation/supplementalcompositetype [Instance Property] `var supplementalCompositeType: VNBarcodeCompositeType { get }` — The supplemental composite type.
vision/vnbarcodeobservation/supplementalpayloaddata [Instance Property] `var supplementalPayloadData: Data? { get }`
vision/vnbarcodeobservation/supplementalpayloadstring [Instance Property] `var supplementalPayloadString: String? { get }` — The supplemental code decoded as a string value.
vision/vnbarcodeobservation/symbology [Instance Property] `var symbology: VNBarcodeSymbology { get }` — The symbology of the observed barcode.

vision/vnbarcodesymbology [Structure] `struct VNBarcodeSymbology` — The barcode symbologies that the framework detects.
vision/vnbarcodesymbology/aztec-6g0vi [Type Property, deprecated (renamed: aztec)] `static var Aztec: VNBarcodeSymbology { get }` — A constant that indicates Aztec symbology.
vision/vnbarcodesymbology/aztec-s3va [Type Property] `static let aztec: VNBarcodeSymbology` — A constant that indicates Aztec symbology.
vision/vnbarcodesymbology/codabar [Type Property] `static let codabar: VNBarcodeSymbology` — A constant that indicates Codabar symbology.
vision/vnbarcodesymbology/code128-1lkm2 [Type Property] `static let code128: VNBarcodeSymbology` — A constant that indicates Code 128 symbology.
vision/vnbarcodesymbology/code128-7spp7 [Type Property, deprecated (renamed: code128)] `static var Code128: VNBarcodeSymbology { get }`
vision/vnbarcodesymbology/code39-2ggrb [Type Property] `static let code39: VNBarcodeSymbology` — A constant that indicates Code 39 symbology.
vision/vnbarcodesymbology/code39-34358 [Type Property, deprecated (renamed: code39)] `static var Code39: VNBarcodeSymbology { get }` — A constant that indicates Code 39 symbology.
vision/vnbarcodesymbology/code39checksum-2jrn [Type Property, deprecated (renamed: code39Checksum)] `static var Code39Checksum: VNBarcodeSymbology { get }` — A constant that indicates Code 39 symbology with a checksum.
vision/vnbarcodesymbology/code39checksum-3jdl6 [Type Property] `static let code39Checksum: VNBarcodeSymbology` — A constant that indicates Code 39 symbology with a checksum.
vision/vnbarcodesymbology/code39fullascii-942jj [Type Property] `static let code39FullASCII: VNBarcodeSymbology` — A constant that indicates Code 39 Full ASCII symbology.
vision/vnbarcodesymbology/code39fullascii-m5wd [Type Property, deprecated (renamed: code39FullASCII)] `static var Code39FullASCII: VNBarcodeSymbology { get }` — A constant that indicates Code 39 Full ASCII symbology.
vision/vnbarcodesymbology/code39fullasciichecksum-5xnfs [Type Property, deprecated (renamed: code39FullASCIIChecksum)] `static var Code39FullASCIIChecksum: VNBarcodeSymbology { get }` — A constant that indicates Code 39 Full ASCII symbology with a checksum.
vision/vnbarcodesymbology/code39fullasciichecksum-6700 [Type Property] `static let code39FullASCIIChecksum: VNBarcodeSymbology` — A constant that indicates Code 39 Full ASCII symbology with a checksum.
vision/vnbarcodesymbology/code93-2geph [Type Property] `static let code93: VNBarcodeSymbology` — A constant that indicates Code 93 symbology.
vision/vnbarcodesymbology/code93-67nn0 [Type Property, deprecated (renamed: code93)] `static var Code93: VNBarcodeSymbology { get }` — A constant that indicates Code 93 symbology.
vision/vnbarcodesymbology/code93i-84cmv [Type Property, deprecated (renamed: code93i)] `static var Code93i: VNBarcodeSymbology { get }` — A constant that indicates Code 93i symbology.
vision/vnbarcodesymbology/code93i-t5q5 [Type Property] `static let code93i: VNBarcodeSymbology` — A constant that indicates Code 93i symbology.
vision/vnbarcodesymbology/datamatrix-2fgc9 [Type Property, deprecated (renamed: dataMatrix)] `static var DataMatrix: VNBarcodeSymbology { get }` — A constant that indicates Data Matrix symbology.
vision/vnbarcodesymbology/datamatrix-6tg7m [Type Property] `static let dataMatrix: VNBarcodeSymbology` — A constant that indicates Data Matrix symbology.
vision/vnbarcodesymbology/ean13-7gb2d [Type Property] `static let ean13: VNBarcodeSymbology` — A constant that indicates EAN-13 symbology.
vision/vnbarcodesymbology/ean13-8ir8e [Type Property, deprecated (renamed: ean13)] `static var EAN13: VNBarcodeSymbology { get }` — A constant that indicates EAN-13 symbology.
vision/vnbarcodesymbology/ean8-4rzbb [Type Property, deprecated (renamed: ean8)] `static var EAN8: VNBarcodeSymbology { get }` — A constant that indicates EAN-8 symbology.
vision/vnbarcodesymbology/ean8-9qg0n [Type Property] `static let ean8: VNBarcodeSymbology` — A constant that indicates EAN-8 symbology.
vision/vnbarcodesymbology/gs1databar [Type Property] `static let gs1DataBar: VNBarcodeSymbology` — A constant that indicates GS1 DataBar symbology.
vision/vnbarcodesymbology/gs1databarexpanded [Type Property] `static let gs1DataBarExpanded: VNBarcodeSymbology` — A constant that indicates GS1 DataBar Expanded symbology.
vision/vnbarcodesymbology/gs1databarlimited [Type Property] `static let gs1DataBarLimited: VNBarcodeSymbology` — A constant that indicates GS1 DataBar Limited symbology.
vision/vnbarcodesymbology/i2of5-1r8e7 [Type Property, deprecated (renamed: i2of5)] `static var I2of5: VNBarcodeSymbology { get }` — A constant that indicates Interleaved 2 of 5 (ITF) symbology.
vision/vnbarcodesymbology/i2of5-cyk4 [Type Property] `static let i2of5: VNBarcodeSymbology` — A constant that indicates Interleaved 2 of 5 (ITF) symbology.
vision/vnbarcodesymbology/i2of5checksum-832s5 [Type Property, deprecated (renamed: i2of5Checksum)] `static var I2of5Checksum: VNBarcodeSymbology { get }` — A constant that indicates Interleaved 2 of 5 (ITF) symbology with a checksum.
vision/vnbarcodesymbology/i2of5checksum-999jm [Type Property] `static let i2of5Checksum: VNBarcodeSymbology` — A constant that indicates Interleaved 2 of 5 (ITF) symbology with a checksum.
vision/vnbarcodesymbology/init(rawvalue:) [Initializer] `init(rawValue: String)` — Creates a symbology with a string value.
vision/vnbarcodesymbology/itf14-1wp9s [Type Property, deprecated (renamed: itf14)] `static var ITF14: VNBarcodeSymbology { get }` — A constant that indicates ITF-14 symbology.
vision/vnbarcodesymbology/itf14-9mbkq [Type Property] `static let itf14: VNBarcodeSymbology` — A constant that indicates ITF-14 symbology.
vision/vnbarcodesymbology/micropdf417 [Type Property] `static let microPDF417: VNBarcodeSymbology` — A constant that indicates MicroPDF417 symbology.
vision/vnbarcodesymbology/microqr [Type Property] `static let microQR: VNBarcodeSymbology` — A constant that indicates MicroQR symbology.
vision/vnbarcodesymbology/msiplessey [Type Property] `static let msiPlessey: VNBarcodeSymbology` — A constant that indicates Modified Plessey symbology.
vision/vnbarcodesymbology/pdf417-56ney [Type Property, deprecated (renamed: pdf417)] `static var PDF417: VNBarcodeSymbology { get }` — A constant that indicates PDF417 symbology.
vision/vnbarcodesymbology/pdf417-8n3oh [Type Property] `static let pdf417: VNBarcodeSymbology` — A constant that indicates PDF417 symbology.
vision/vnbarcodesymbology/qr-2l1ve [Type Property] `static let qr: VNBarcodeSymbology` — A constant that indicates Quick Response (QR) symbology.
vision/vnbarcodesymbology/qr-2zqax [Type Property, deprecated (renamed: qr)] `static var QR: VNBarcodeSymbology { get }` — A constant that indicates Quick Response (QR) symbology.
vision/vnbarcodesymbology/upce-1jtoc [Type Property] `static let upce: VNBarcodeSymbology` — A constant that indicates UPC-E symbology.
vision/vnbarcodesymbology/upce-7qps5 [Type Property, deprecated (renamed: upce)] `static var UPCE: VNBarcodeSymbology { get }` — A constant that indicates UPC-E symbology.

vision/vncalculateimageaestheticsscoresrequest [Class] `class VNCalculateImageAestheticsScoresRequest` — An object that analyzes an image for aesthetically pleasing attributes.
vision/vncalculateimageaestheticsscoresrequest/results [Instance Property] `var results: [VNImageAestheticsScoresObservation]? { get }` — The results of the aesthetics request.

vision/vncalculateimageaestheticsscoresrequestrevision1 [Global Variable] `var VNCalculateImageAestheticsScoresRequestRevision1: Int { get }` — A value that indicates the first revision for an aesthetics scores request.

vision/vnchirality [Enumeration] `@frozen enum VNChirality` — Constants that the define the chirality, or handedness, of a pose.
vision/vnchirality/init(rawvalue:) [Initializer] `init?(rawValue: Int)`
vision/vnchirality/left [Case] `case left` — Indicates a left-handed pose.
vision/vnchirality/right [Case] `case right` — Indicates a right-handed pose.
vision/vnchirality/unknown [Case] `case unknown` — Indicates that the pose chirality is unknown.

vision/vncircle [Class] `class VNCircle` — An immutable 2D circle represented by its center point and radius.
vision/vncircle/center [Instance Property] `var center: VNPoint { get }` — The circle’s center point.
vision/vncircle/contains(_:) [Instance Method] `func contains(_ point: VNPoint) -> Bool` — Determines if this circle, including its boundary, contains the specified point.
vision/vncircle/contains(_:incircumferentialringofwidth:) [Instance Method] `func contains(_ point: VNPoint, inCircumferentialRingOfWidth ringWidth: Double) -> Bool` — Determines if a ring around this circle’s circumference contains the specified point.
vision/vncircle/diameter [Instance Property] `var diameter: Double { get }` — The circle’s diameter.
vision/vncircle/init(center:diameter:) [Initializer] `convenience init(center: VNPoint, diameter: Double)` — Creates a circle with the specified center and diameter.
vision/vncircle/init(center:radius:) [Initializer] `init(center: VNPoint, radius: Double)` — Creates a circle with the specified center and radius.
vision/vncircle/init(coder:) [Initializer] `init?(coder: NSCoder)`
vision/vncircle/radius [Instance Property] `var radius: Double { get }` — The circle’s radius.
vision/vncircle/zero [Type Property] `class var zero: VNCircle { get }` — A circle object centered at the origin, with a radius of zero.

vision/vnclassificationobservation [Class] `class VNClassificationObservation` — An object that represents classification information that an image-analysis request produces.
vision/vnclassificationobservation/hasminimumprecision(_:forrecall:) [Instance Method] `func hasMinimumPrecision(_ minimumPrecision: Float, forRecall recall: Float) -> Bool` — Determines whether the observation for a specific recall has a minimum precision value.
vision/vnclassificationobservation/hasminimumrecall(_:forprecision:) [Instance Method] `func hasMinimumRecall(_ minimumRecall: Float, forPrecision precision: Float) -> Bool` — Determines whether the observation for a specific precision has a minimum recall value.
vision/vnclassificationobservation/hasprecisionrecallcurve [Instance Property] `var hasPrecisionRecallCurve: Bool { get }` — A Boolean variable indicating whether the observation contains precision and recall curves.
vision/vnclassificationobservation/identifier [Instance Property] `var identifier: String { get }` — Classification label identifying the type of observation.

vision/vnclassifyimagerequest [Class] `class VNClassifyImageRequest` — A request to classify an image.
vision/vnclassifyimagerequest/knownclassifications(forrevision:) [Type Method, deprecated] `class func knownClassifications(forRevision requestRevision: Int) throws -> [VNClassificationObservation]` — Requests the collection of classifications that the Vision framework recognizes.
vision/vnclassifyimagerequest/results [Instance Property] `var results: [VNClassificationObservation]? { get }` — The results of the image classification request.
vision/vnclassifyimagerequest/supportedidentifiers() [Instance Method] `func supportedIdentifiers() throws -> [String]` — Returns the classification identifiers that the request supports in its current configuration.

vision/vnclassifyimagerequestrevision1 [Global Variable] `var VNClassifyImageRequestRevision1: Int { get }` — A constant for specifying the first revision of the image-classification request.

vision/vnclassifyimagerequestrevision2 [Global Variable] `var VNClassifyImageRequestRevision2: Int { get }` — A value that indicates the second revision for an image-classification request.

vision/vncomputestage [Structure] `struct VNComputeStage` — Types that represent the compute stage.
vision/vncomputestage/init(rawvalue:) [Initializer] `init(rawValue: String)` — Creates a compute stage with the value you specify.
vision/vncomputestage/main [Type Property] `static let main: VNComputeStage` — A stage that represents where the system performs the main functionality.
vision/vncomputestage/postprocessing [Type Property] `static let postProcessing: VNComputeStage` — A stage that represents where the system performs additional analysis from the main compute stage.

vision/vnconfidence [Type Alias] `typealias VNConfidence = Float` — A type alias for the confidence value of an observation.

vision/vncontour [Class] `class VNContour` — A class that represents a detected contour in an image.
vision/vncontour/aspectratio [Instance Property] `var aspectRatio: Float { get }` — The aspect ratio of the contour.
vision/vncontour/childcontour(at:) [Instance Method] `func childContour(at childContourIndex: Int) throws -> VNContour` — Retrieves the child contour object at the specified index.
vision/vncontour/childcontourcount [Instance Property] `var childContourCount: Int { get }` — The total number of detected child contours.
vision/vncontour/childcontours [Instance Property] `var childContours: [VNContour] { get }` — An array of contours that this contour encloses.
vision/vncontour/indexpath [Instance Property] `var indexPath: IndexPath { get }` — The contour object’s index path.
vision/vncontour/normalizedpath [Instance Property] `var normalizedPath: CGPath { get }` — The contour object as a path in normalized coordinates.
vision/vncontour/normalizedpoints-8n2s5 [Instance Property] `@nonobjc var normalizedPoints: [simd_float2] { get }` — The contour’s array of points in normalized coordinates.
vision/vncontour/pointcount [Instance Property] `var pointCount: Int { get }` — The contour’s number of points.
vision/vncontour/polygonapproximation(epsilon:) [Instance Method] `func polygonApproximation(epsilon: Float) throws -> VNContour` — Simplifies the contour to a polygon using a Ramer-Douglas-Peucker algorithm.

vision/vncontoursobservation [Class] `class VNContoursObservation` — An object that represents the detected contours in an image.
vision/vncontoursobservation/contour(at:)-52odo [Instance Method] `func contour(at indexPath: IndexPath) throws -> VNContour` — Retrieves the contour object at the specified index path.
vision/vncontoursobservation/contour(at:)-9on0y [Instance Method] `func contour(at contourIndex: Int) throws -> VNContour` — Retrieves the contour object at the specified index, irrespective of hierarchy.
vision/vncontoursobservation/contourcount [Instance Property] `var contourCount: Int { get }` — The total number of detected contours.
vision/vncontoursobservation/normalizedpath [Instance Property] `var normalizedPath: CGPath { get }` — The detected contours as a path object in normalized coordinates.
vision/vncontoursobservation/toplevelcontourcount [Instance Property] `var topLevelContourCount: Int { get }` — The total number of detected top-level contours.
vision/vncontoursobservation/toplevelcontours [Instance Property] `var topLevelContours: [VNContour] { get }` — An array of contours that don’t have another contour enclosing them.

vision/vncoremlfeaturevalueobservation [Class] `class VNCoreMLFeatureValueObservation` — An object that represents a collection of key-value information that a Core ML image-analysis request produces.
vision/vncoremlfeaturevalueobservation/featurename [Instance Property] `var featureName: String { get }` — The name used in the model description of the CoreML model that produced this observation.
vision/vncoremlfeaturevalueobservation/featurevalue [Instance Property] `@NSCopying var featureValue: MLFeatureValue { get }` — The feature result of a VNCoreMLRequest that outputs neither a classification nor an image.

vision/vncoremlmodel [Class] `class VNCoreMLModel` — A container for the model to use with Vision requests.
vision/vncoremlmodel/featureprovider [Instance Property] `var featureProvider: (any MLFeatureProvider)? { get set }` — An optional object to support inputs outside Vision.
vision/vncoremlmodel/init(for:) [Initializer] `convenience init(for model: MLModel) throws` — Creates a model container to use with a Core ML request.
vision/vncoremlmodel/init(formlmodel:) [Initializer] `convenience init(forMLModel model: MLModel) throws`
vision/vncoremlmodel/inputimagefeaturename [Instance Property] `var inputImageFeatureName: String { get set }` — The name of the feature value that Vision sets from the request handler.

vision/vncoremlrequest [Class] `class VNCoreMLRequest` — An image-analysis request that uses a Core ML model to process images.
vision/vncoremlrequest/imagecropandscaleoption [Instance Property] `var imageCropAndScaleOption: VNImageCropAndScaleOption { get set }` — An optional setting that tells the Vision algorithm how to scale an input image.
vision/vncoremlrequest/init(model:) [Initializer] `convenience init(model: VNCoreMLModel)` — Creates a model container to use with an image analysis request based on the model you provide.
vision/vncoremlrequest/init(model:completionhandler:) [Initializer] `init(model: VNCoreMLModel, completionHandler: VNRequestCompletionHandler? = nil)` — Creates a model container to use with an image analysis request based on the model you provide, with an optional completion handler.
vision/vncoremlrequest/model [Instance Property] `var model: VNCoreMLModel { get }` — The model to base the image analysis request on.

vision/vncoremlrequestrevision1 [Global Variable] `var VNCoreMLRequestRevision1: Int { get }` — A constant for specifying revision 1 of a Core ML request.

vision/vndegrees [Type Alias] `typealias VNDegrees = Float` — A typealias for expressing tolerance angles in Vision.

vision/vndetectanimalbodyposerequest [Class] `class VNDetectAnimalBodyPoseRequest` — A request that detects an animal body pose.
vision/vndetectanimalbodyposerequest/results [Instance Property] `var results: [VNAnimalBodyPoseObservation]? { get }` — The animal body pose the request observes.
vision/vndetectanimalbodyposerequest/supportedjointnames [Instance Property] `@nonobjc var supportedJointNames: [VNAnimalBodyPoseObservation.JointName] { get throws }` — Retrieves the joint names the request supports.
vision/vndetectanimalbodyposerequest/supportedjointsgroupnames [Instance Property] `@nonobjc var supportedJointsGroupNames: [VNAnimalBodyPoseObservation.JointsGroupName] { get throws }` — Retrieves the joint group names the request supports.

vision/vndetectanimalbodyposerequestrevision1 [Global Variable] `var VNDetectAnimalBodyPoseRequestRevision1: Int { get }` — A value that indicates the first revision for an animal body-pose request.

vision/vndetectbarcodesrequest [Class] `class VNDetectBarcodesRequest` — A request that detects barcodes in an image.
vision/vndetectbarcodesrequest/coalescecompositesymbologies [Instance Property] `var coalesceCompositeSymbologies: Bool { get set }` — A Boolean value that indicates whether to coalesce multiple codes based on the symbology.
vision/vndetectbarcodesrequest/results [Instance Property] `var results: [VNBarcodeObservation]? { get }` — The results of a barcode detection request.
vision/vndetectbarcodesrequest/supportedsymbologies [Type Property, deprecated] `class var supportedSymbologies: [VNBarcodeSymbology] { get }` — The array of barcode symbologies that the request supports.
vision/vndetectbarcodesrequest/supportedsymbologies() [Instance Method] `func supportedSymbologies() throws -> [VNBarcodeSymbology]` — Returns the barcode symbologies that the request supports.
vision/vndetectbarcodesrequest/symbologies [Instance Property] `var symbologies: [VNBarcodeSymbology] { get set }` — The barcode symbologies that the request detects in an image.

vision/vndetectbarcodesrequestrevision1 [Global Variable, deprecated (renamed: VNDetectBarcodesRequestRevision3)] `var VNDetectBarcodesRequestRevision1: Int { get }` — A constant for specifying revision 1 of the barcode detection request.

vision/vndetectbarcodesrequestrevision2 [Global Variable, deprecated (renamed: VNDetectBarcodesRequestRevision3)] `var VNDetectBarcodesRequestRevision2: Int { get }` — A constant for specifying revision 2 of the barcode detection request.

vision/vndetectbarcodesrequestrevision3 [Global Variable] `var VNDetectBarcodesRequestRevision3: Int { get }` — A constant for specifying revision 3 of the barcode detection request.

vision/vndetectbarcodesrequestrevision4 [Global Variable] `var VNDetectBarcodesRequestRevision4: Int { get }` — A value that indicates the fourth revision for a barcode request.

vision/vndetectcontourrequestrevision1 [Global Variable] `var VNDetectContourRequestRevision1: Int { get }` — A constant for specifying revision 1 of the contours detection request.

vision/vndetectcontoursrequest [Class] `class VNDetectContoursRequest` — A request that detects the contours of the edges of an image.
vision/vndetectcontoursrequest/contrastadjustment [Instance Property] `var contrastAdjustment: Float { get set }` — The amount by which to adjust the image contrast.
vision/vndetectcontoursrequest/contrastpivot [Instance Property] `var contrastPivot: NSNumber? { get set }` — The pixel value to use as a pivot for the contrast.
vision/vndetectcontoursrequest/detectdarkonlight [Instance Property, deprecated] `var detectDarkOnLight: Bool { get set }` — A Boolean value that indicates whether the request detects a dark object on a light background.
vision/vndetectcontoursrequest/detectsdarkonlight [Instance Property] `var detectsDarkOnLight: Bool { get set }` — A Boolean value that indicates whether the request detects a dark object on a light background to aid in detection.
vision/vndetectcontoursrequest/maximumimagedimension [Instance Property] `var maximumImageDimension: Int { get set }` — The maximum image dimension to use for contour detection.
vision/vndetectcontoursrequest/results [Instance Property] `var results: [VNContoursObservation]? { get }` — The results of the request to detect contours.

vision/vndetectdocumentsegmentationrequest [Class] `class VNDetectDocumentSegmentationRequest` — An object that detects rectangular regions that contain text in the input image.
vision/vndetectdocumentsegmentationrequest/results [Instance Property] `var results: [VNRectangleObservation]? { get }` — The results of a document segmentation request.

vision/vndetectdocumentsegmentationrequestrevision1 [Global Variable] `var VNDetectDocumentSegmentationRequestRevision1: Int { get }` — A constant for specifying revision 1 of the document segmentation request.

vision/vndetectedobjectobservation [Class] `class VNDetectedObjectObservation` — An observation that provides the position and extent of an image feature that an image- analysis request detects.
vision/vndetectedobjectobservation/boundingbox [Instance Property] `var boundingBox: CGRect { get }` — The bounding box of the object that the request detects.
vision/vndetectedobjectobservation/globalsegmentationmask [Instance Property] `var globalSegmentationMask: VNPixelBufferObservation? { get }` — A resulting pixel buffer from a request to generate a segmentation mask for an image.
vision/vndetectedobjectobservation/init(boundingbox:) [Initializer] `convenience init(boundingBox: CGRect)` — Creates an observation with a bounding box.
vision/vndetectedobjectobservation/init(requestrevision:boundingbox:) [Initializer] `convenience init(requestRevision: Int, boundingBox: CGRect)` — Creates an observation with a revision number and bounding box.

vision/vndetectedpoint [Class] `class VNDetectedPoint` — An object that represents a normalized point in an image, along with a confidence value.
vision/vndetectedpoint/confidence [Instance Property] `var confidence: VNConfidence { get }` — A confidence score that indicates the detected point’s accuracy.

vision/vndetectfacecapturequalityrequest [Class] `class VNDetectFaceCaptureQualityRequest` — A request that produces a floating-point number that represents the capture quality of a face in a photo.
vision/vndetectfacecapturequalityrequest/results [Instance Property] `var results: [VNFaceObservation]? { get }` — The results of the face-capture quality request.

vision/vndetectfacecapturequalityrequestrevision1 [Global Variable] `var VNDetectFaceCaptureQualityRequestRevision1: Int { get }` — A constant for specifying revision 1 of the face capture detection request.

vision/vndetectfacecapturequalityrequestrevision2 [Global Variable] `var VNDetectFaceCaptureQualityRequestRevision2: Int { get }` — Revision 2 of the request algorithm.

vision/vndetectfacecapturequalityrequestrevision3 [Global Variable] `var VNDetectFaceCaptureQualityRequestRevision3: Int { get }` — A value that indicates the third revision for a face capture-quality request.

vision/vndetectfacelandmarksrequest [Class] `class VNDetectFaceLandmarksRequest` — An image-analysis request that finds facial features like eyes and mouth in an image.
vision/vndetectfacelandmarksrequest/constellation [Instance Property] `var constellation: VNRequestFaceLandmarksConstellation { get set }` — A variable that describes how a face landmarks request orders or enumerates the resulting features.
vision/vndetectfacelandmarksrequest/results [Instance Property] `var results: [VNFaceObservation]? { get }` — The results of the face landmarks request.
vision/vndetectfacelandmarksrequest/revision(_:supportsconstellation:) [Type Method] `class func revision(_ requestRevision: Int, supportsConstellation constellation: VNRequestFaceLandmarksConstellation) -> Bool` — Returns a Boolean value that indicates whether a revision supports a constellation.

vision/vndetectfacelandmarksrequestrevision1 [Global Variable, deprecated (renamed: VNDetectFaceLandmarksRequestRevision2)] `var VNDetectFaceLandmarksRequestRevision1: Int { get }` — A constant for specifying revision 1 of the face landmarks detection request.

vision/vndetectfacelandmarksrequestrevision2 [Global Variable] `var VNDetectFaceLandmarksRequestRevision2: Int { get }` — A constant for specifying revision 2 of the face landmarks detection request.

vision/vndetectfacelandmarksrequestrevision3 [Global Variable] `var VNDetectFaceLandmarksRequestRevision3: Int { get }` — A constant for specifying revision 3 of the face landmarks detection request.

vision/vndetectfacerectanglesrequest [Class] `class VNDetectFaceRectanglesRequest` — A request that finds faces within an image.
vision/vndetectfacerectanglesrequest/results [Instance Property] `var results: [VNFaceObservation]? { get }` — The results of the face detection request.

vision/vndetectfacerectanglesrequestrevision1 [Global Variable, deprecated (renamed: VNDetectFaceRectanglesRequestRevision2)] `var VNDetectFaceRectanglesRequestRevision1: Int { get }` — A constant for specifying revision 1 of the face rectangles detection request.

vision/vndetectfacerectanglesrequestrevision2 [Global Variable] `var VNDetectFaceRectanglesRequestRevision2: Int { get }` — A constant for specifying revision 2 of the face rectangles detection request.

vision/vndetectfacerectanglesrequestrevision3 [Global Variable] `var VNDetectFaceRectanglesRequestRevision3: Int { get }` — A constant for specifying revision 3 of the face rectangles detection request.

vision/vndetecthorizonrequest [Class] `class VNDetectHorizonRequest` — An image-analysis request that determines the horizon angle in an image.
vision/vndetecthorizonrequest/results [Instance Property] `var results: [VNHorizonObservation]? { get }` — The results of the horizon detection request.

vision/vndetecthorizonrequestrevision1 [Global Variable] `var VNDetectHorizonRequestRevision1: Int { get }` — A constant for specifying revision 1 of the horizon detection request.

vision/vndetecthumanbodypose3drequest [Class] `class VNDetectHumanBodyPose3DRequest` — A request that detects points on human bodies in 3D space, relative to the camera.
vision/vndetecthumanbodypose3drequest/init() [Initializer] `init()` — Creates a new request with no completion handler.
vision/vndetecthumanbodypose3drequest/init(completionhandler:) [Initializer] `init(completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new 3D body pose request with a completion handler.
vision/vndetecthumanbodypose3drequest/results [Instance Property] `var results: [VNHumanBodyPose3DObservation]? { get }` — The 3D body pose the request observes.
vision/vndetecthumanbodypose3drequest/supportedjointnames [Instance Property] `@nonobjc var supportedJointNames: [VNHumanBodyPose3DObservation.JointName] { get throws }` — Returns the joint group names the request supports.
vision/vndetecthumanbodypose3drequest/supportedjointsgroupnames [Instance Property] `@nonobjc var supportedJointsGroupNames: [VNHumanBodyPose3DObservation.JointsGroupName] { get throws }` — Returns the joint names the request supports.

vision/vndetecthumanbodypose3drequestrevision1 [Global Variable] `var VNDetectHumanBodyPose3DRequestRevision1: Int { get }` — A value that indicates the first revision for a human 3D body pose request.

vision/vndetecthumanbodyposerequest [Class] `class VNDetectHumanBodyPoseRequest` — A request that detects a human body pose.
vision/vndetecthumanbodyposerequest/results [Instance Property] `var results: [VNHumanBodyPoseObservation]? { get }` — The observed body poses.
vision/vndetecthumanbodyposerequest/supportedjointnames [Instance Property] `@nonobjc var supportedJointNames: [VNHumanBodyPoseObservation.JointName] { get throws }` — Retrieves the supported joint names.
vision/vndetecthumanbodyposerequest/supportedjointnames(forrevision:) [Type Method, deprecated] `class func supportedJointNames(forRevision revision: Int) throws -> [VNHumanBodyPoseObservation.JointName]` — Retrieves the supported joint names for a revision.
vision/vndetecthumanbodyposerequest/supportedjointsgroupnames [Instance Property] `@nonobjc var supportedJointsGroupNames: [VNHumanBodyPoseObservation.JointsGroupName] { get throws }` — Retrieves the supported joint group names.
vision/vndetecthumanbodyposerequest/supportedjointsgroupnames(forrevision:) [Type Method, deprecated] `class func supportedJointsGroupNames(forRevision revision: Int) throws -> [VNHumanBodyPoseObservation.JointsGroupName]` — Retrieves the supported joint group names for a revision.

vision/vndetecthumanbodyposerequestrevision1 [Global Variable] `var VNDetectHumanBodyPoseRequestRevision1: Int { get }` — A constant for specifying revision 1 of the body pose detection request.

vision/vndetecthumanhandposerequest [Class] `class VNDetectHumanHandPoseRequest` — A request that detects a human hand pose.
vision/vndetecthumanhandposerequest/maximumhandcount [Instance Property] `var maximumHandCount: Int { get set }` — The maximum number of hands to detect in an image.
vision/vndetecthumanhandposerequest/results [Instance Property] `var results: [VNHumanHandPoseObservation]? { get }` — The observed hand poses.
vision/vndetecthumanhandposerequest/supportedjointnames [Instance Property] `@nonobjc var supportedJointNames: [VNHumanHandPoseObservation.JointName] { get throws }` — Retrieves the supported joint names.
vision/vndetecthumanhandposerequest/supportedjointnames(forrevision:) [Type Method, deprecated] `class func supportedJointNames(forRevision revision: Int) throws -> [VNHumanHandPoseObservation.JointName]` — Retrieves the supported joint names for a revision.
vision/vndetecthumanhandposerequest/supportedjointsgroupnames [Instance Property] `@nonobjc var supportedJointsGroupNames: [VNHumanHandPoseObservation.JointsGroupName] { get throws }` — Retrieves the supported joint group names.
vision/vndetecthumanhandposerequest/supportedjointsgroupnames(forrevision:) [Type Method, deprecated] `class func supportedJointsGroupNames(forRevision revision: Int) throws -> [VNHumanHandPoseObservation.JointsGroupName]` — Retrieves the supported joint group names for a revision.

vision/vndetecthumanhandposerequestrevision1 [Global Variable] `var VNDetectHumanHandPoseRequestRevision1: Int { get }` — A constant for specifying revision 1 of the hand pose detection request.

vision/vndetecthumanrectanglesrequest [Class] `class VNDetectHumanRectanglesRequest` — A request that finds rectangular regions that contain people in an image.
vision/vndetecthumanrectanglesrequest/results [Instance Property] `var results: [VNHumanObservation]? { get }` — The results of the request to find rectangular regions that contain people in an image.
vision/vndetecthumanrectanglesrequest/upperbodyonly [Instance Property] `var upperBodyOnly: Bool { get set }` — A Boolean value that indicates whether the request requires detecting a full body or upper body only to produce a result.

vision/vndetecthumanrectanglesrequestrevision1 [Global Variable] `var VNDetectHumanRectanglesRequestRevision1: Int { get }` — A constant for specifying revision 1 of the human rectangles detection request.

vision/vndetecthumanrectanglesrequestrevision2 [Global Variable] `var VNDetectHumanRectanglesRequestRevision2: Int { get }` — A constant for specifying revision 2 of the human rectangles detection request.

vision/vndetectrectanglesrequest [Class] `class VNDetectRectanglesRequest` — An image-analysis request that finds projected rectangular regions in an image.
vision/vndetectrectanglesrequest/maximumaspectratio [Instance Property] `var maximumAspectRatio: VNAspectRatio { get set }` — A `float` specifying the maximum aspect ratio of the rectangle to detect, defined as the shorter dimension over the longer dimension.
vision/vndetectrectanglesrequest/maximumobservations [Instance Property] `var maximumObservations: Int { get set }` — An integer specifying the maximum number of rectangles Vision returns.
vision/vndetectrectanglesrequest/minimumaspectratio [Instance Property] `var minimumAspectRatio: VNAspectRatio { get set }` — A `float` specifying the minimum aspect ratio of the rectangle to detect, defined as the shorter dimension over the longer dimension.
vision/vndetectrectanglesrequest/minimumconfidence [Instance Property] `var minimumConfidence: VNConfidence { get set }` — A value specifying the minimum acceptable confidence level.
vision/vndetectrectanglesrequest/minimumsize [Instance Property] `var minimumSize: Float { get set }` — The minimum size of a rectangle to detect, as a proportion of the smallest dimension.
vision/vndetectrectanglesrequest/quadraturetolerance [Instance Property] `var quadratureTolerance: VNDegrees { get set }` — A float specifying the number of degrees a rectangle corner angle can deviate from 90°.
vision/vndetectrectanglesrequest/results [Instance Property] `var results: [VNRectangleObservation]? { get }` — The results of the request to detect rectangles.

vision/vndetectrectanglesrequestrevision1 [Global Variable] `var VNDetectRectanglesRequestRevision1: Int { get }` — A constant for specifying revision 1 of the rectangle detection request.

vision/vndetecttextrectanglesrequest [Class] `class VNDetectTextRectanglesRequest` — An image-analysis request that finds regions of visible text in an image.
vision/vndetecttextrectanglesrequest/reportcharacterboxes [Instance Property] `var reportCharacterBoxes: Bool { get set }` — A Boolean value that indicates whether the request detects character bounding boxes.
vision/vndetecttextrectanglesrequest/results [Instance Property] `var results: [VNTextObservation]? { get }` — The results of the request to detect text rectangles.

vision/vndetecttextrectanglesrequestrevision1 [Global Variable] `var VNDetectTextRectanglesRequestRevision1: Int { get }` — A constant for specifying revision 1 of the text rectangles detection request.

vision/vndetecttrajectoriesrequest [Class] `class VNDetectTrajectoriesRequest` — A request that detects the trajectories of shapes moving along a parabolic path.
vision/vndetecttrajectoriesrequest/init(frameanalysisspacing:trajectorylength:completionhandler:) [Initializer] `init(frameAnalysisSpacing: CMTime, trajectoryLength: Int, completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request to detect trajectories.
vision/vndetecttrajectoriesrequest/maximumobjectsize [Instance Property, deprecated] `var maximumObjectSize: Float { get set }` — The maximum radius of the tracked shape’s bounding circle.
vision/vndetecttrajectoriesrequest/minimumobjectsize [Instance Property, deprecated] `var minimumObjectSize: Float { get set }` — The minimum radius of the tracked shape’s bounding circle.
vision/vndetecttrajectoriesrequest/objectmaximumnormalizedradius [Instance Property] `var objectMaximumNormalizedRadius: Float { get set }` — The maximum radius of the bounding circle of the object to track.
vision/vndetecttrajectoriesrequest/objectminimumnormalizedradius [Instance Property] `var objectMinimumNormalizedRadius: Float { get set }` — The minimum radius of the bounding circle of the object to track.
vision/vndetecttrajectoriesrequest/results [Instance Property] `var results: [VNTrajectoryObservation]? { get }` — The array of detected trajectory observations.
vision/vndetecttrajectoriesrequest/targetframetime [Instance Property] `var targetFrameTime: CMTime { get set }` — The requested target frame time for processing trajectory detection.
vision/vndetecttrajectoriesrequest/trajectorylength [Instance Property] `var trajectoryLength: Int { get }` — The number of points to detect before calculating a trajectory.

vision/vndetecttrajectoriesrequestrevision1 [Global Variable] `var VNDetectTrajectoriesRequestRevision1: Int { get }` — A constant for specifying revision 1 of the trajectories detection request.

vision/vnelementtype [Enumeration] `enum VNElementType` — An enumeration of the type of element in feature print data.
vision/vnelementtype/double [Case] `case double` — The elements are double-precision floating-point numbers.
vision/vnelementtype/float [Case] `case float` — The elements are floating-point numbers.
vision/vnelementtype/init(rawvalue:) [Initializer] `init?(rawValue: UInt)`
vision/vnelementtype/unknown [Case] `case unknown` — The element type isn’t known.

vision/vnelementtypesize(_:) [Function] `func VNElementTypeSize(_ elementType: VNElementType) -> Int` — Returns the size of a feature print element.

vision/vnerrorcode [Enumeration] `enum VNErrorCode` — Constants that identify errors from the framework.
vision/vnerrorcode/dataunavailable [Case] `case dataUnavailable` — The data isn’t available.
vision/vnerrorcode/init(rawvalue:) [Initializer] `init?(rawValue: Int)`
vision/vnerrorcode/internalerror [Case] `case internalError` — An internal error occurred within the framework.
vision/vnerrorcode/invalidargument [Case] `case invalidArgument` — An app passed an invalid parameter to a request.
vision/vnerrorcode/invalidformat [Case] `case invalidFormat` — The format of the image is invalid.
vision/vnerrorcode/invalidimage [Case] `case invalidImage` — The image is invalid.
vision/vnerrorcode/invalidmodel [Case] `case invalidModel` — The Core ML model is incompatible with the request.
vision/vnerrorcode/invalidoperation [Case] `case invalidOperation` — An app requested an unsupported operation.
vision/vnerrorcode/invalidoption [Case] `case invalidOption` — An app specified an invalid option on a request.
vision/vnerrorcode/ioerror [Case] `case ioError` — An I/O error for an image, image sequence, or Core ML model.
vision/vnerrorcode/missingoption [Case] `case missingOption` — A request is missing a required option.
vision/vnerrorcode/notimplemented [Case] `case notImplemented` — The method isn’t implemented in the underlying model.
vision/vnerrorcode/ok [Case] `case OK` — The operation finished without error.
vision/vnerrorcode/operationfailed [Case] `case operationFailed` — The requested operation failed.
vision/vnerrorcode/outofboundserror [Case] `case outOfBoundsError` — An app attempted to access data that’s out-of-bounds.
vision/vnerrorcode/outofmemory [Case] `case outOfMemory` — The system doesn’t have enough memory to complete the request.
vision/vnerrorcode/requestcancelled [Case] `case requestCancelled` — An app canceled the request.
vision/vnerrorcode/resourcecorrupted [Case] `case resourceCorrupted`
vision/vnerrorcode/resourceunavailable [Case] `case resourceUnavailable`
vision/vnerrorcode/timeout [Case] `case timeout` — The requested operation timed out.
vision/vnerrorcode/timestampnotfound [Case] `case timeStampNotFound` — The system can’t find a timestamp.
vision/vnerrorcode/turicoreerrorcode [Case] `case turiCoreErrorCode` — An error occurred during Create ML training due to an invalid transformation or image.
vision/vnerrorcode/unknownerror [Case] `case unknownError` — An unidentified error occurred.
vision/vnerrorcode/unsupportedcomputedevice [Case] `case unsupportedComputeDevice` — An app requested an unsupported compute device.
vision/vnerrorcode/unsupportedcomputestage [Case] `case unsupportedComputeStage` — An app requested an unsupported compute stage.
vision/vnerrorcode/unsupportedrequest [Case] `case unsupportedRequest` — An app attempted an unsupported request.
vision/vnerrorcode/unsupportedrevision [Case] `case unsupportedRevision` — An app specified an unsupported request revision.

vision/vnerrordomain [Global Variable] `let VNErrorDomain: String` — The domain of errors that the framework generates.

vision/vnfacelandmarkregion [Class] `class VNFaceLandmarkRegion` — The abstract superclass for information about a specific face landmark.
vision/vnfacelandmarkregion/init(coder:) [Initializer] `init?(coder: NSCoder)`
vision/vnfacelandmarkregion/pointcount [Instance Property] `var pointCount: Int { get }` — The number of points in the face region.

vision/vnfacelandmarkregion2d [Class] `class VNFaceLandmarkRegion2D` — 2D geometry information for a specific facial feature.
vision/vnfacelandmarkregion2d/normalizedpoints-7s7im [Instance Property] `@nonobjc var normalizedPoints: [CGPoint] { get }` — The array of normalized landmark points.
vision/vnfacelandmarkregion2d/pointsclassification [Instance Property] `var pointsClassification: VNPointsClassification { get }` — An enumeration that describes how to interpret the points the region provides.
vision/vnfacelandmarkregion2d/pointsinimage(imagesize:) [Instance Method] `@nonobjc func pointsInImage(imageSize: CGSize) -> [CGPoint]` — Returns an array containing landmark points in the coordinate space of the specified image size.
vision/vnfacelandmarkregion2d/precisionestimatesperpoint-5jl22 [Instance Property] `@nonobjc var precisionEstimatesPerPoint: [Float]? { get }` — Requests an array of precision estimates for each landmark point.

vision/vnfacelandmarks [Class] `class VNFaceLandmarks` — The abstract superclass for containers of face landmark information.
vision/vnfacelandmarks/confidence [Instance Property] `var confidence: VNConfidence { get }` — A confidence estimate for the detected landmarks.
vision/vnfacelandmarks/init(coder:) [Initializer] `init?(coder: NSCoder)`

vision/vnfacelandmarks2d [Class] `class VNFaceLandmarks2D` — A collection of facial features that a request detects.
vision/vnfacelandmarks2d/allpoints [Instance Property] `var allPoints: VNFaceLandmarkRegion2D? { get }` — The region containing all face landmark points.
vision/vnfacelandmarks2d/facecontour [Instance Property] `var faceContour: VNFaceLandmarkRegion2D? { get }` — The region containing points that trace the face contour from the left cheek, over the chin, to the right cheek.
vision/vnfacelandmarks2d/innerlips [Instance Property] `var innerLips: VNFaceLandmarkRegion2D? { get }` — The region containing points that outline the space between the lips.
vision/vnfacelandmarks2d/lefteye [Instance Property] `var leftEye: VNFaceLandmarkRegion2D? { get }` — The region containing points that outline the left eye.
vision/vnfacelandmarks2d/lefteyebrow [Instance Property] `var leftEyebrow: VNFaceLandmarkRegion2D? { get }` — The region containing points that trace the left eyebrow.
vision/vnfacelandmarks2d/leftpupil [Instance Property] `var leftPupil: VNFaceLandmarkRegion2D? { get }` — The region containing the point where the left pupil is located.
vision/vnfacelandmarks2d/medianline [Instance Property] `var medianLine: VNFaceLandmarkRegion2D? { get }` — The region containing points that trace a vertical line down the center of the face.
vision/vnfacelandmarks2d/nose [Instance Property] `var nose: VNFaceLandmarkRegion2D? { get }` — The region containing points that outline the nose.
vision/vnfacelandmarks2d/nosecrest [Instance Property] `var noseCrest: VNFaceLandmarkRegion2D? { get }` — The region containing points that trace the center crest of the nose.
vision/vnfacelandmarks2d/outerlips [Instance Property] `var outerLips: VNFaceLandmarkRegion2D? { get }` — The region containing points that outline the outside of the lips.
vision/vnfacelandmarks2d/righteye [Instance Property] `var rightEye: VNFaceLandmarkRegion2D? { get }` — The region containing points that outline the right eye.
vision/vnfacelandmarks2d/righteyebrow [Instance Property] `var rightEyebrow: VNFaceLandmarkRegion2D? { get }` — The region containing points that trace the right eyebrow.
vision/vnfacelandmarks2d/rightpupil [Instance Property] `var rightPupil: VNFaceLandmarkRegion2D? { get }` — The region containing the point where the right pupil is located.

vision/vnfaceobservation [Class] `class VNFaceObservation` — Face or facial-feature information that an image analysis request detects.
vision/vnfaceobservation/facecapturequality-bjg5 [Instance Property] `@nonobjc var faceCaptureQuality: Float? { get }` — A value that indicates the quality of the face capture.
vision/vnfaceobservation/init(requestrevision:boundingbox:roll:yaw:) [Initializer, deprecated] `convenience init(requestRevision: Int, boundingBox: CGRect, roll: NSNumber?, yaw: NSNumber?)` — Creates an observation that contains the roll and yaw of the face.
vision/vnfaceobservation/init(requestrevision:boundingbox:roll:yaw:pitch:) [Initializer] `convenience init(requestRevision: Int, boundingBox: CGRect, roll: NSNumber?, yaw: NSNumber?, pitch: NSNumber?)` — Creates an observation that contains the roll, yaw, and pitch of the face.
vision/vnfaceobservation/landmarks [Instance Property] `var landmarks: VNFaceLandmarks2D? { get }` — The facial features of the detected face.
vision/vnfaceobservation/pitch [Instance Property] `var pitch: NSNumber? { get }` — The pitch angle of a face in radians.
vision/vnfaceobservation/roll [Instance Property] `var roll: NSNumber? { get }` — The roll angle of a face in radians.
vision/vnfaceobservation/yaw [Instance Property] `var yaw: NSNumber? { get }` — The yaw angle of a face in radians.

vision/vnfaceobservationaccepting [Protocol] `protocol VNFaceObservationAccepting : NSObjectProtocol` — An image analysis request that operates on face observations.
vision/vnfaceobservationaccepting/inputfaceobservations [Instance Property] `var inputFaceObservations: [VNFaceObservation]? { get set }` — An array of VNFaceObservation objects to process as part of the request.

vision/vnfeatureprintobservation [Class] `class VNFeaturePrintObservation` — An observation that provides the recognized feature print.
vision/vnfeatureprintobservation/computedistance(_:to:) [Instance Method] `func computeDistance(_ outDistance: UnsafeMutablePointer<Float>, to featurePrint: VNFeaturePrintObservation) throws` — Computes the distance between two feature print observations.
vision/vnfeatureprintobservation/data [Instance Property] `var data: Data { get }` — The feature print data.
vision/vnfeatureprintobservation/elementcount [Instance Property] `var elementCount: Int { get }` — The total number of elements in the data.
vision/vnfeatureprintobservation/elementtype [Instance Property] `var elementType: VNElementType { get }` — The type of each element in the data.

vision/vngenerateattentionbasedsaliencyimagerequest [Class] `class VNGenerateAttentionBasedSaliencyImageRequest` — An object that produces a heat map that identifies the parts of an image most likely to draw attention.
vision/vngenerateattentionbasedsaliencyimagerequest/results [Instance Property] `var results: [VNSaliencyImageObservation]? { get }` — The results of the image saliency request.

vision/vngenerateattentionbasedsaliencyimagerequestrevision1 [Global Variable] `var VNGenerateAttentionBasedSaliencyImageRequestRevision1: Int { get }` — A constant for specifying revision 1 of the image saliency request.

vision/vngenerateattentionbasedsaliencyimagerequestrevision2 [Global Variable] `var VNGenerateAttentionBasedSaliencyImageRequestRevision2: Int { get }` — A value that indicates the second revision for an attention-saliency image request.

vision/vngenerateforegroundinstancemaskrequest [Class] `class VNGenerateForegroundInstanceMaskRequest` — A request that generates an instance mask of noticable objects to separate from the background.
vision/vngenerateforegroundinstancemaskrequest/results [Instance Property] `var results: [VNInstanceMaskObservation]? { get }` — The instance masks the request observes.

vision/vngenerateforegroundinstancemaskrequestrevision1 [Global Variable] `var VNGenerateForegroundInstanceMaskRequestRevision1: Int { get }` — A constant for specifying the first revision of the foreground instance mask request.

vision/vngenerateimagefeatureprintrequest [Class] `class VNGenerateImageFeaturePrintRequest` — An image-based request to generate feature prints from an image.
vision/vngenerateimagefeatureprintrequest/imagecropandscaleoption [Instance Property] `var imageCropAndScaleOption: VNImageCropAndScaleOption { get set }` — An optional setting that tells the algorithm how to scale an input image before generating the feature print.
vision/vngenerateimagefeatureprintrequest/results [Instance Property] `var results: [VNFeaturePrintObservation]? { get }` — The results of the feature print request.

vision/vngenerateimagefeatureprintrequestrevision1 [Global Variable] `var VNGenerateImageFeaturePrintRequestRevision1: Int { get }` — A constant for specifying the first revision of the feature-print request.

vision/vngenerateimagefeatureprintrequestrevision2 [Global Variable] `var VNGenerateImageFeaturePrintRequestRevision2: Int { get }` — A value that indicates the second revision for a feature-print request.

vision/vngenerateobjectnessbasedsaliencyimagerequest [Class] `class VNGenerateObjectnessBasedSaliencyImageRequest` — A request that generates a heat map that identifies the parts of an image most likely to represent objects.
vision/vngenerateobjectnessbasedsaliencyimagerequest/results [Instance Property] `var results: [VNSaliencyImageObservation]? { get }` — The results of the image saliency request.

vision/vngenerateobjectnessbasedsaliencyimagerequestrevision1 [Global Variable] `var VNGenerateObjectnessBasedSaliencyImageRequestRevision1: Int { get }` — A constant for specifying revision 1 of the image saliency request.

vision/vngenerateobjectnessbasedsaliencyimagerequestrevision2 [Global Variable] `var VNGenerateObjectnessBasedSaliencyImageRequestRevision2: Int { get }` — A value that indicates the second revision for an image-classification request.

vision/vngenerateopticalflowrequest [Class] `class VNGenerateOpticalFlowRequest` — An object that generates directional change vectors for each pixel in the targeted image.
vision/vngenerateopticalflowrequest/computationaccuracy-swift.enum [Enumeration] `enum ComputationAccuracy` — The supported optical flow accuracy levels.
vision/vngenerateopticalflowrequest/computationaccuracy-swift.enum/high [Case] `case high` — High accuracy.
vision/vngenerateopticalflowrequest/computationaccuracy-swift.enum/init(rawvalue:) [Initializer] `init?(rawValue: UInt)`
vision/vngenerateopticalflowrequest/computationaccuracy-swift.enum/low [Case] `case low` — Low accuracy.
vision/vngenerateopticalflowrequest/computationaccuracy-swift.enum/medium [Case] `case medium` — Medium accuracy.
vision/vngenerateopticalflowrequest/computationaccuracy-swift.enum/veryhigh [Case] `case veryHigh` — Very high accuracy.
vision/vngenerateopticalflowrequest/computationaccuracy-swift.property [Instance Property] `var computationAccuracy: VNGenerateOpticalFlowRequest.ComputationAccuracy { get set }` — The accuracy level for computing optical flow.
vision/vngenerateopticalflowrequest/keepnetworkoutput [Instance Property] `var keepNetworkOutput: Bool { get set }` — A Boolean value that indicates whether to keep the raw pixel buffer coming from the machine learning network.
vision/vngenerateopticalflowrequest/outputpixelformat [Instance Property] `var outputPixelFormat: OSType { get set }` — The output buffer’s pixel format.
vision/vngenerateopticalflowrequest/results [Instance Property] `var results: [VNPixelBufferObservation]? { get }` — The results of the request to generate optical flow.

vision/vngenerateopticalflowrequestrevision1 [Global Variable] `var VNGenerateOpticalFlowRequestRevision1: Int { get }` — A constant for specifying revision 1 of the optical flow generation request.

vision/vngenerateopticalflowrequestrevision2 [Global Variable] `var VNGenerateOpticalFlowRequestRevision2: Int { get }` — A constant for specifying revision 2 of the optical flow generation request.

vision/vngeneratepersoninstancemaskrequest [Class] `class VNGeneratePersonInstanceMaskRequest` — An object that produces a mask of individual people it finds in the input image.
vision/vngeneratepersoninstancemaskrequest/results [Instance Property] `var results: [VNInstanceMaskObservation]? { get }` — The results of the instance mask request.

vision/vngeneratepersoninstancemaskrequestrevision1 [Global Variable] `var VNGeneratePersonInstanceMaskRequestRevision1: Int { get }` — A constant for specifying revision 1 of the person instance mask request.

vision/vngeneratepersonsegmentationrequest [Class] `class VNGeneratePersonSegmentationRequest` — An object that produces a matte image for a person it finds in the input image.
vision/vngeneratepersonsegmentationrequest/init() [Initializer] `init()` — Creates a generate person segmentation request.
vision/vngeneratepersonsegmentationrequest/init(completionhandler:) [Initializer] `init(completionHandler: VNRequestCompletionHandler? = nil)` — Creates a generate person segmentation request with a completion handler.
vision/vngeneratepersonsegmentationrequest/outputpixelformat [Instance Property] `var outputPixelFormat: OSType { get set }` — The pixel format of the output image.
vision/vngeneratepersonsegmentationrequest/qualitylevel-swift.enum [Enumeration] `enum QualityLevel` — Constants that define the levels of quality for a person segmentation request.
vision/vngeneratepersonsegmentationrequest/qualitylevel-swift.enum/accurate [Case] `case accurate` — Prefers image quality over performance.
vision/vngeneratepersonsegmentationrequest/qualitylevel-swift.enum/balanced [Case] `case balanced` — Prefers processing that balances image quality and performance.
vision/vngeneratepersonsegmentationrequest/qualitylevel-swift.enum/fast [Case] `case fast` — Prefers performance over image quality.
vision/vngeneratepersonsegmentationrequest/qualitylevel-swift.enum/init(rawvalue:) [Initializer] `init?(rawValue: UInt)`
vision/vngeneratepersonsegmentationrequest/qualitylevel-swift.property [Instance Property] `var qualityLevel: VNGeneratePersonSegmentationRequest.QualityLevel { get set }` — A value that indicates how the request balances accuracy and performance.
vision/vngeneratepersonsegmentationrequest/results [Instance Property] `var results: [VNPixelBufferObservation]? { get }` — The results of the segmentation request.
vision/vngeneratepersonsegmentationrequest/supportedoutputpixelformats() [Instance Method] `func supportedOutputPixelFormats() throws -> [NSNumber]` — Returns a list of output pixel formats that the request supports.

vision/vngeneratepersonsegmentationrequestrevision1 [Global Variable] `var VNGeneratePersonSegmentationRequestRevision1: Int { get }` — A constant for specifying revision 1 of the person segmentation generation request.

vision/vngeometryutils [Class] `class VNGeometryUtils` — Utility methods to determine the geometries of various Vision types.
vision/vngeometryutils/boundingcircle(for:)-423ll [Type Method] `class func boundingCircle(for contour: VNContour) throws -> VNCircle` — Calculates a bounding circle for the specified contour object.
vision/vngeometryutils/boundingcircle(for:)-9dggv [Type Method] `class func boundingCircle(for points: [VNPoint]) throws -> VNCircle` — Calculates a bounding circle for the specified array of points.
vision/vngeometryutils/boundingcircle(forsimdpoints:pointcount:) [Type Method] `class func boundingCircle(forSIMDPoints points: UnsafePointer<simd_float2>, pointCount: Int) throws -> VNCircle` — Calculates a bounding circle for the specified points.
vision/vngeometryutils/calculatearea(_:for:orientedarea:) [Type Method] `class func calculateArea(_ area: UnsafeMutablePointer<Double>, for contour: VNContour, orientedArea: Bool) throws` — Calculates the area for the specified contour.
vision/vngeometryutils/calculateperimeter(_:for:) [Type Method] `class func calculatePerimeter(_ perimeter: UnsafeMutablePointer<Double>, for contour: VNContour) throws` — Calculates the perimeter of a closed contour.

vision/vnhomographicimageregistrationrequest [Class] `class VNHomographicImageRegistrationRequest` — An image-analysis request that determines the perspective warp matrix necessary to align the content of two images.
vision/vnhomographicimageregistrationrequest/results [Instance Property] `var results: [VNImageHomographicAlignmentObservation]? { get }` — The results of the image registration request.

vision/vnhomographicimageregistrationrequestrevision1 [Global Variable] `var VNHomographicImageRegistrationRequestRevision1: Int { get }` — A constant for specifying revision 1 of the homographic image registration request.

vision/vnhorizonobservation [Class] `class VNHorizonObservation` — The horizon angle information that an image-analysis request detects.
vision/vnhorizonobservation/angle [Instance Property] `var angle: CGFloat { get }` — The angle of the observed horizon.
vision/vnhorizonobservation/transform [Instance Property] `var transform: CGAffineTransform { get }` — The transform to apply to the detected horizon.
vision/vnhorizonobservation/transform(forimagewidth:height:) [Instance Method] `func transform(forImageWidth width: Int, height: Int) -> CGAffineTransform` — Creates an affine transform for the specified image width and height.

vision/vnhumanbodypose3dobservation [Class] `class VNHumanBodyPose3DObservation` — An observation that provides the 3D body points the request recognizes.
vision/vnhumanbodypose3dobservation/availablejointnames [Instance Property] `var availableJointNames: [VNHumanBodyPose3DObservation.JointName] { get }` — The names of the available joints in the observation.
vision/vnhumanbodypose3dobservation/availablejointsgroupnames [Instance Property] `var availableJointsGroupNames: [VNHumanBodyPose3DObservation.JointsGroupName] { get }` — The available joint group names in the observation.
vision/vnhumanbodypose3dobservation/bodyheight [Instance Property] `var bodyHeight: Float { get }` — The estimated human body height, in meters.
vision/vnhumanbodypose3dobservation/cameraoriginmatrix [Instance Property] `var cameraOriginMatrix: simd_float4x4 { get }` — A transform from the skeleton hip to the camera.
vision/vnhumanbodypose3dobservation/camerarelativeposition(_:) [Instance Method] `@nonobjc func cameraRelativePosition(_ jointName: VNHumanBodyPose3DObservation.JointName) throws -> simd_float4x4` — Returns a position relative to the camera for the body joint you specify.
vision/vnhumanbodypose3dobservation/heightestimation-swift.enum [Enumeration] `enum HeightEstimation` — Constants that identify body height estimation techniques.
vision/vnhumanbodypose3dobservation/heightestimation-swift.enum/init(rawvalue:) [Initializer] `init?(rawValue: Int)`
vision/vnhumanbodypose3dobservation/heightestimation-swift.enum/measured [Case] `case measured` — A technique that uses LiDAR depth data to measure body height, in meters.
vision/vnhumanbodypose3dobservation/heightestimation-swift.enum/reference [Case] `case reference` — A technique that uses a reference height.
vision/vnhumanbodypose3dobservation/heightestimation-swift.property [Instance Property] `var heightEstimation: VNHumanBodyPose3DObservation.HeightEstimation { get }` — The technique the framework uses to estimate body height.
vision/vnhumanbodypose3dobservation/jointname [Structure] `struct JointName` — The joint names for a 3D body pose.
vision/vnhumanbodypose3dobservation/jointname/centerhead [Type Property] `static let centerHead: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the center of the head.
vision/vnhumanbodypose3dobservation/jointname/centershoulder [Type Property] `static let centerShoulder: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the point between the shoulders.
vision/vnhumanbodypose3dobservation/jointname/init(rawvalue:) [Initializer] `init(rawValue: VNRecognizedPointKey)` — Creates a joint name with the key you specify.
vision/vnhumanbodypose3dobservation/jointname/leftankle [Type Property] `static let leftAnkle: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the left ankle.
vision/vnhumanbodypose3dobservation/jointname/leftelbow [Type Property] `static let leftElbow: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the left elbow.
vision/vnhumanbodypose3dobservation/jointname/lefthip [Type Property] `static let leftHip: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the left hip.
vision/vnhumanbodypose3dobservation/jointname/leftknee [Type Property] `static let leftKnee: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the left knee.
vision/vnhumanbodypose3dobservation/jointname/leftshoulder [Type Property] `static let leftShoulder: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the left shoulder.
vision/vnhumanbodypose3dobservation/jointname/leftwrist [Type Property] `static let leftWrist: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the left wrist.
vision/vnhumanbodypose3dobservation/jointname/rightankle [Type Property] `static let rightAnkle: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the right ankle.
vision/vnhumanbodypose3dobservation/jointname/rightelbow [Type Property] `static let rightElbow: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the right elbow.
vision/vnhumanbodypose3dobservation/jointname/righthip [Type Property] `static let rightHip: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the right hip.
vision/vnhumanbodypose3dobservation/jointname/rightknee [Type Property] `static let rightKnee: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the right knee.
vision/vnhumanbodypose3dobservation/jointname/rightshoulder [Type Property] `static let rightShoulder: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the right shoulder.
vision/vnhumanbodypose3dobservation/jointname/rightwrist [Type Property] `static let rightWrist: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the right wrist.
vision/vnhumanbodypose3dobservation/jointname/root [Type Property] `static let root: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the point between the left hip and right hip.
vision/vnhumanbodypose3dobservation/jointname/spine [Type Property] `static let spine: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the spine.
vision/vnhumanbodypose3dobservation/jointname/tophead [Type Property] `static let topHead: VNHumanBodyPose3DObservation.JointName` — A joint name that represents the top of the head.
vision/vnhumanbodypose3dobservation/jointsgroupname [Structure] `struct JointsGroupName` — The joint group names for a 3D body pose.
vision/vnhumanbodypose3dobservation/jointsgroupname/all [Type Property] `static let all: VNHumanBodyPose3DObservation.JointsGroupName` — A group name that represents all joints.
vision/vnhumanbodypose3dobservation/jointsgroupname/head [Type Property] `static let head: VNHumanBodyPose3DObservation.JointsGroupName` — A group name that represents the head joints.
vision/vnhumanbodypose3dobservation/jointsgroupname/init(rawvalue:) [Initializer] `init(rawValue: VNRecognizedPointGroupKey)` — Creates a joint name with the key you specify.
vision/vnhumanbodypose3dobservation/jointsgroupname/leftarm [Type Property] `static let leftArm: VNHumanBodyPose3DObservation.JointsGroupName` — A group name that represents the left arm joints.
vision/vnhumanbodypose3dobservation/jointsgroupname/leftleg [Type Property] `static let leftLeg: VNHumanBodyPose3DObservation.JointsGroupName` — A group name that represents the left leg joints.
vision/vnhumanbodypose3dobservation/jointsgroupname/rightarm [Type Property] `static let rightArm: VNHumanBodyPose3DObservation.JointsGroupName` — A group name that represents the right arm joints.
vision/vnhumanbodypose3dobservation/jointsgroupname/rightleg [Type Property] `static let rightLeg: VNHumanBodyPose3DObservation.JointsGroupName` — A group name that represents the right leg joints.
vision/vnhumanbodypose3dobservation/jointsgroupname/torso [Type Property] `static let torso: VNHumanBodyPose3DObservation.JointsGroupName` — A group name that represents the torso joints.
vision/vnhumanbodypose3dobservation/parentjointname(_:) [Instance Method] `func parentJointName(_ jointName: VNHumanBodyPose3DObservation.JointName) -> VNHumanBodyPose3DObservation.JointName?` — Returns the parent joint of the joint name you specify.
vision/vnhumanbodypose3dobservation/pointinimage(_:) [Instance Method] `func pointInImage(_ jointName: VNHumanBodyPose3DObservation.JointName) throws -> VNPoint` — Returns a 2D point for the joint name you specify, relative to the input image.
vision/vnhumanbodypose3dobservation/recognizedpoint(_:) [Instance Method] `func recognizedPoint(_ jointName: VNHumanBodyPose3DObservation.JointName) throws -> VNHumanBodyRecognizedPoint3D` — Returns the point for a joint name that the observation recognizes.
vision/vnhumanbodypose3dobservation/recognizedpoints(_:) [Instance Method] `func recognizedPoints(_ jointsGroupName: VNHumanBodyPose3DObservation.JointsGroupName) throws -> [VNHumanBodyPose3DObservation.JointName : VNHumanBodyRecognizedPoint3D]` — Returns a collection of points for the group name you specify.

vision/vnhumanbodyposeobservation [Class] `class VNHumanBodyPoseObservation` — An observation that provides the body points the analysis recognized.
vision/vnhumanbodyposeobservation/availablejointnames [Instance Property] `var availableJointNames: [VNHumanBodyPoseObservation.JointName] { get }` — The names of the available joints in the observation.
vision/vnhumanbodyposeobservation/availablejointsgroupnames [Instance Property] `var availableJointsGroupNames: [VNHumanBodyPoseObservation.JointsGroupName] { get }` — The available joint group names in the observation.
vision/vnhumanbodyposeobservation/jointname [Structure] `struct JointName` — The supported joint names for the body pose.
vision/vnhumanbodyposeobservation/jointname/init(rawvalue:) [Initializer] `init(rawValue: VNRecognizedPointKey)` — Creates a joint name with a recognized point key.
vision/vnhumanbodyposeobservation/jointname/leftankle [Type Property] `static let leftAnkle: VNHumanBodyPoseObservation.JointName` — The left ankle.
vision/vnhumanbodyposeobservation/jointname/leftear [Type Property] `static let leftEar: VNHumanBodyPoseObservation.JointName` — The left ear.
vision/vnhumanbodyposeobservation/jointname/leftelbow [Type Property] `static let leftElbow: VNHumanBodyPoseObservation.JointName` — The left elbow.
vision/vnhumanbodyposeobservation/jointname/lefteye [Type Property] `static let leftEye: VNHumanBodyPoseObservation.JointName` — The left eye.
vision/vnhumanbodyposeobservation/jointname/lefthip [Type Property] `static let leftHip: VNHumanBodyPoseObservation.JointName` — The left hip.
vision/vnhumanbodyposeobservation/jointname/leftknee [Type Property] `static let leftKnee: VNHumanBodyPoseObservation.JointName` — The left knee.
vision/vnhumanbodyposeobservation/jointname/leftshoulder [Type Property] `static let leftShoulder: VNHumanBodyPoseObservation.JointName` — The left shoulder.
vision/vnhumanbodyposeobservation/jointname/leftwrist [Type Property] `static let leftWrist: VNHumanBodyPoseObservation.JointName` — The left wrist.
vision/vnhumanbodyposeobservation/jointname/neck [Type Property] `static let neck: VNHumanBodyPoseObservation.JointName` — The neck.
vision/vnhumanbodyposeobservation/jointname/nose [Type Property] `static let nose: VNHumanBodyPoseObservation.JointName` — The nose.
vision/vnhumanbodyposeobservation/jointname/rightankle [Type Property] `static let rightAnkle: VNHumanBodyPoseObservation.JointName` — The right ankle.
vision/vnhumanbodyposeobservation/jointname/rightear [Type Property] `static let rightEar: VNHumanBodyPoseObservation.JointName` — The right ear.
vision/vnhumanbodyposeobservation/jointname/rightelbow [Type Property] `static let rightElbow: VNHumanBodyPoseObservation.JointName` — The right elbow.
vision/vnhumanbodyposeobservation/jointname/righteye [Type Property] `static let rightEye: VNHumanBodyPoseObservation.JointName` — The right eye.
vision/vnhumanbodyposeobservation/jointname/righthip [Type Property] `static let rightHip: VNHumanBodyPoseObservation.JointName` — The right hip.
vision/vnhumanbodyposeobservation/jointname/rightknee [Type Property] `static let rightKnee: VNHumanBodyPoseObservation.JointName` — The right knee.
vision/vnhumanbodyposeobservation/jointname/rightshoulder [Type Property] `static let rightShoulder: VNHumanBodyPoseObservation.JointName` — The right shoulder.
vision/vnhumanbodyposeobservation/jointname/rightwrist [Type Property] `static let rightWrist: VNHumanBodyPoseObservation.JointName` — The right wrist.
vision/vnhumanbodyposeobservation/jointname/root [Type Property] `static let root: VNHumanBodyPoseObservation.JointName` — The root (waist).
vision/vnhumanbodyposeobservation/jointsgroupname [Structure] `struct JointsGroupName` — The supported joint group names for the body pose.
vision/vnhumanbodyposeobservation/jointsgroupname/all [Type Property] `static let all: VNHumanBodyPoseObservation.JointsGroupName` — All body point groups.
vision/vnhumanbodyposeobservation/jointsgroupname/face [Type Property] `static let face: VNHumanBodyPoseObservation.JointsGroupName` — The face.
vision/vnhumanbodyposeobservation/jointsgroupname/init(rawvalue:) [Initializer] `init(rawValue: VNRecognizedPointGroupKey)` — Creates a joint group name with a recognized point group key.
vision/vnhumanbodyposeobservation/jointsgroupname/leftarm [Type Property] `static let leftArm: VNHumanBodyPoseObservation.JointsGroupName` — The left arm.
vision/vnhumanbodyposeobservation/jointsgroupname/leftleg [Type Property] `static let leftLeg: VNHumanBodyPoseObservation.JointsGroupName` — The left leg.
vision/vnhumanbodyposeobservation/jointsgroupname/rightarm [Type Property] `static let rightArm: VNHumanBodyPoseObservation.JointsGroupName` — The right arm.
vision/vnhumanbodyposeobservation/jointsgroupname/rightleg [Type Property] `static let rightLeg: VNHumanBodyPoseObservation.JointsGroupName` — The right leg.
vision/vnhumanbodyposeobservation/jointsgroupname/torso [Type Property] `static let torso: VNHumanBodyPoseObservation.JointsGroupName` — The torso.
vision/vnhumanbodyposeobservation/recognizedpoint(_:) [Instance Method] `func recognizedPoint(_ jointName: VNHumanBodyPoseObservation.JointName) throws -> VNRecognizedPoint` — Retrieves the recognized point for a joint name.
vision/vnhumanbodyposeobservation/recognizedpoints(_:) [Instance Method] `func recognizedPoints(_ jointsGroupName: VNHumanBodyPoseObservation.JointsGroupName) throws -> [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint]` — Retrieves the recognized points associated with the joint group name.

vision/vnhumanbodyrecognizedpoint3d [Class] `class VNHumanBodyRecognizedPoint3D` — A recognized 3D point that includes a parent joint.
vision/vnhumanbodyrecognizedpoint3d/localposition [Instance Property] `var localPosition: simd_float4x4 { get }` — The three-dimensional position.
vision/vnhumanbodyrecognizedpoint3d/parentjoint [Instance Property] `var parentJoint: VNHumanBodyPose3DObservation.JointName { get }` — The parent joint in the observation.

vision/vnhumanhandposeobservation [Class] `class VNHumanHandPoseObservation` — An observation that provides the hand points the analysis recognized.
vision/vnhumanhandposeobservation/availablejointnames [Instance Property] `var availableJointNames: [VNHumanHandPoseObservation.JointName] { get }` — The names of the available joints in the observation.
vision/vnhumanhandposeobservation/availablejointsgroupnames [Instance Property] `var availableJointsGroupNames: [VNHumanHandPoseObservation.JointsGroupName] { get }` — The joint group names available in the observation.
vision/vnhumanhandposeobservation/chirality [Instance Property] `var chirality: VNChirality { get }` — The chirality, or handedness, of a pose.
vision/vnhumanhandposeobservation/jointname [Structure] `struct JointName` — The supported joint names for the hand pose.
vision/vnhumanhandposeobservation/jointname/indexdip [Type Property] `static let indexDIP: VNHumanHandPoseObservation.JointName` — The index finger’s distal interphalangeal (DIP) joint.
vision/vnhumanhandposeobservation/jointname/indexmcp [Type Property] `static let indexMCP: VNHumanHandPoseObservation.JointName` — The index finger’s metacarpophalangeal (MCP) joint.
vision/vnhumanhandposeobservation/jointname/indexpip [Type Property] `static let indexPIP: VNHumanHandPoseObservation.JointName` — The index finger’s proximal interphalangeal (PIP) joint.
vision/vnhumanhandposeobservation/jointname/indextip [Type Property] `static let indexTip: VNHumanHandPoseObservation.JointName` — The tip of the index finger.
vision/vnhumanhandposeobservation/jointname/init(rawvalue:) [Initializer] `init(rawValue: VNRecognizedPointKey)` — Creates a joint name with a recognized point key.
vision/vnhumanhandposeobservation/jointname/littledip [Type Property] `static let littleDIP: VNHumanHandPoseObservation.JointName` — The little finger’s distal interphalangeal (DIP) joint.
vision/vnhumanhandposeobservation/jointname/littlemcp [Type Property] `static let littleMCP: VNHumanHandPoseObservation.JointName` — The little finger’s metacarpophalangeal (MCP) joint.
vision/vnhumanhandposeobservation/jointname/littlepip [Type Property] `static let littlePIP: VNHumanHandPoseObservation.JointName` — The little finger’s proximal interphalangeal (PIP) joint.
vision/vnhumanhandposeobservation/jointname/littletip [Type Property] `static let littleTip: VNHumanHandPoseObservation.JointName` — The tip of the little finger.
vision/vnhumanhandposeobservation/jointname/middledip [Type Property] `static let middleDIP: VNHumanHandPoseObservation.JointName` — The middle finger’s distal interphalangeal (DIP) joint.
vision/vnhumanhandposeobservation/jointname/middlemcp [Type Property] `static let middleMCP: VNHumanHandPoseObservation.JointName` — The middle finger’s metacarpophalangeal (MCP) joint.
vision/vnhumanhandposeobservation/jointname/middlepip [Type Property] `static let middlePIP: VNHumanHandPoseObservation.JointName` — The middle finger’s proximal interphalangeal (PIP) joint.
vision/vnhumanhandposeobservation/jointname/middletip [Type Property] `static let middleTip: VNHumanHandPoseObservation.JointName` — The tip of the middle finger.
vision/vnhumanhandposeobservation/jointname/ringdip [Type Property] `static let ringDIP: VNHumanHandPoseObservation.JointName` — The ring finger’s distal interphalangeal (DIP) joint.
vision/vnhumanhandposeobservation/jointname/ringmcp [Type Property] `static let ringMCP: VNHumanHandPoseObservation.JointName` — The ring finger’s metacarpophalangeal (MCP) joint.
vision/vnhumanhandposeobservation/jointname/ringpip [Type Property] `static let ringPIP: VNHumanHandPoseObservation.JointName` — The ring finger’s proximal interphalangeal (PIP) joint.
vision/vnhumanhandposeobservation/jointname/ringtip [Type Property] `static let ringTip: VNHumanHandPoseObservation.JointName` — The tip of the ring finger.
vision/vnhumanhandposeobservation/jointname/thumbcmc [Type Property] `static let thumbCMC: VNHumanHandPoseObservation.JointName` — The thumb’s carpometacarpal (CMC) joint.
vision/vnhumanhandposeobservation/jointname/thumbip [Type Property] `static let thumbIP: VNHumanHandPoseObservation.JointName` — The thumb’s interphalangeal (IP) joint.
vision/vnhumanhandposeobservation/jointname/thumbmp [Type Property] `static let thumbMP: VNHumanHandPoseObservation.JointName` — The thumb’s metacarpophalangeal (MP) joint.
vision/vnhumanhandposeobservation/jointname/thumbtip [Type Property] `static let thumbTip: VNHumanHandPoseObservation.JointName` — The tip of the thumb.
vision/vnhumanhandposeobservation/jointname/wrist [Type Property] `static let wrist: VNHumanHandPoseObservation.JointName` — The wrist.
vision/vnhumanhandposeobservation/jointsgroupname [Structure] `struct JointsGroupName` — The supported joint group names for the hand pose.
vision/vnhumanhandposeobservation/jointsgroupname/all [Type Property] `static let all: VNHumanHandPoseObservation.JointsGroupName` — All hand group names.
vision/vnhumanhandposeobservation/jointsgroupname/indexfinger [Type Property] `static let indexFinger: VNHumanHandPoseObservation.JointsGroupName` — The index finger.
vision/vnhumanhandposeobservation/jointsgroupname/init(rawvalue:) [Initializer] `init(rawValue: VNRecognizedPointGroupKey)` — Creates a joint group name with a recognized point group key.
vision/vnhumanhandposeobservation/jointsgroupname/littlefinger [Type Property] `static let littleFinger: VNHumanHandPoseObservation.JointsGroupName` — The little finger.
vision/vnhumanhandposeobservation/jointsgroupname/middlefinger [Type Property] `static let middleFinger: VNHumanHandPoseObservation.JointsGroupName` — The middle finger.
vision/vnhumanhandposeobservation/jointsgroupname/ringfinger [Type Property] `static let ringFinger: VNHumanHandPoseObservation.JointsGroupName` — The ring finger.
vision/vnhumanhandposeobservation/jointsgroupname/thumb [Type Property] `static let thumb: VNHumanHandPoseObservation.JointsGroupName` — The thumb.
vision/vnhumanhandposeobservation/recognizedpoint(_:) [Instance Method] `func recognizedPoint(_ jointName: VNHumanHandPoseObservation.JointName) throws -> VNRecognizedPoint` — Retrieves the recognized point for a joint name.
vision/vnhumanhandposeobservation/recognizedpoints(_:) [Instance Method] `func recognizedPoints(_ jointsGroupName: VNHumanHandPoseObservation.JointsGroupName) throws -> [VNHumanHandPoseObservation.JointName : VNRecognizedPoint]` — Retrieves the recognized points associated with the joint group name.

vision/vnhumanobservation [Class] `class VNHumanObservation` — An object that represents a person that the request detects.
vision/vnhumanobservation/upperbodyonly [Instance Property] `var upperBodyOnly: Bool { get }` — A Boolean value that indicates whether the observation represents an upper-body or full-body rectangle.

vision/vnimageaestheticsscoresobservation [Class] `class VNImageAestheticsScoresObservation` — An object that represents the overall score of aesthetic attributes for an image.
vision/vnimageaestheticsscoresobservation/isutility [Instance Property] `var isUtility: Bool { get }` — A Boolean value that represents images that are not necessarily of poor image quality, but may not have memorable or exciting content.
vision/vnimageaestheticsscoresobservation/overallscore [Instance Property] `var overallScore: Float { get }` — A score which incorporates aesthetic score, failure score, and utility labels.

vision/vnimagealignmentobservation [Class] `class VNImageAlignmentObservation` — The abstract superclass for image-analysis results that describe the relative alignment of two images.

vision/vnimagebasedrequest [Class] `class VNImageBasedRequest` — The abstract superclass for image-analysis requests that focus on a specific part of an image.
vision/vnimagebasedrequest/regionofinterest [Instance Property] `var regionOfInterest: CGRect { get set }` — The region of the image in which Vision will perform the request.

vision/vnimagecropandscaleoption [Enumeration] `enum VNImageCropAndScaleOption` — Options that define how Vision crops and scales an input-image.
vision/vnimagecropandscaleoption/centercrop [Case] `case centerCrop` — An option that scales the image to fit its shorter side within the input dimensions, while preserving its aspect ratio, and center-crops the image.
vision/vnimagecropandscaleoption/init(rawvalue:) [Initializer] `init?(rawValue: UInt)`
vision/vnimagecropandscaleoption/scalefill [Case] `case scaleFill` — An option that scales the image to fill the input dimensions, resizing it if necessary.
vision/vnimagecropandscaleoption/scalefillrotate90ccw [Case] `case scaleFillRotate90CCW` — An option that rotates the image 90 degrees counterclockwise and then scales it to fill the input dimensions.
vision/vnimagecropandscaleoption/scalefit [Case] `case scaleFit` — An option that scales the image to fit its longer side within the input dimensions, while preserving its aspect ratio, and center-crops the image.
vision/vnimagecropandscaleoption/scalefitrotate90ccw [Case] `case scaleFitRotate90CCW` — An option that rotates the image 90 degrees counterclockwise and then scales it, while preserving its aspect ratio, to fit on the long side.

vision/vnimagehomographicalignmentobservation [Class] `class VNImageHomographicAlignmentObservation` — An object that represents a perspective warp transformation.
vision/vnimagehomographicalignmentobservation/warptransform [Instance Property] `var warpTransform: matrix_float3x3 { get }` — The warp transform matrix to morph the floating image into the reference image.

vision/vnimageoption [Structure] `struct VNImageOption` — An option key passed into an image request handler that takes an auxiliary image.
vision/vnimageoption/cameraintrinsics [Type Property] `static let cameraIntrinsics: VNImageOption` — An option to specify the camera intrinstics.
vision/vnimageoption/cicontext [Type Property] `static let ciContext: VNImageOption` — An option key to specify the context to use in the handler’s Core Image operations.
vision/vnimageoption/init(rawvalue:) [Initializer] `init(rawValue: String)` — Initializes an option key using its string name.
vision/vnimageoption/properties [Type Property] `static let properties: VNImageOption` — The dictionary from the image source that contains the metadata for algorithms like horizon detection.

vision/vnimagepointforfacelandmarkpoint(_:_:_:_:) [Function] `func VNImagePointForFaceLandmarkPoint(_ faceLandmarkPoint: vector_float2, _ faceBoundingBox: CGRect, _ imageWidth: Int, _ imageHeight: Int) -> CGPoint` — Returns the image coordinates of a specified face landmark point.

vision/vnimagepointfornormalizedpoint(_:_:_:) [Function] `func VNImagePointForNormalizedPoint(_ normalizedPoint: CGPoint, _ imageWidth: Int, _ imageHeight: Int) -> CGPoint` — Projects a point in normalized coordinates into image coordinates.

vision/vnimagepointfornormalizedpointusingregionofinterest(_:_:_:_:) [Function] `func VNImagePointForNormalizedPointUsingRegionOfInterest(_ normalizedPoint: CGPoint, _ imageWidth: Int, _ imageHeight: Int, _ roi: CGRect) -> CGPoint` — Projects a point from a region of interest within the normalized coordinates into image coordinates.

vision/vnimagerectfornormalizedrect(_:_:_:) [Function] `func VNImageRectForNormalizedRect(_ normalizedRect: CGRect, _ imageWidth: Int, _ imageHeight: Int) -> CGRect` — Projects a rectangle from normalized coordinates into image coordinates.

vision/vnimagerectfornormalizedrectusingregionofinterest(_:_:_:_:) [Function] `func VNImageRectForNormalizedRectUsingRegionOfInterest(_ normalizedRect: CGRect, _ imageWidth: Int, _ imageHeight: Int, _ roi: CGRect) -> CGRect` — Projects a rectangle from a region of interest within the normalized coordinates into image coordinates.

vision/vnimageregistrationrequest [Class] `class VNImageRegistrationRequest` — The abstract superclass for image-analysis requests that align images according to their content.

vision/vnimagerequesthandler [Class] `class VNImageRequestHandler` — An object that processes one or more image-analysis request pertaining to a single image.
vision/vnimagerequesthandler/init(cgimage:options:)-4qda6 [Initializer] `init(cgImage image: CGImage, options: [VNImageOption : Any] = [:])` — Creates a handler to be used for performing requests on Core Graphics images.
vision/vnimagerequesthandler/init(cgimage:options:)-5tp19 [Initializer] `init(CGImage image: CGImage, options: [VNImageOption : Any] = [:])`
vision/vnimagerequesthandler/init(cgimage:orientation:options:)-63ojm [Initializer] `init(cgImage image: CGImage, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])` — Creates a handler to be used for performing requests on a Core Graphics image with known orientation.
vision/vnimagerequesthandler/init(cgimage:orientation:options:)-8imhf [Initializer] `init(CGImage image: CGImage, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])`
vision/vnimagerequesthandler/init(ciimage:options:)-4wf33 [Initializer] `init(ciImage image: CIImage, options: [VNImageOption : Any] = [:])` — Creates a handler to use for performing requests on Core Image image data.
vision/vnimagerequesthandler/init(ciimage:options:)-55zel [Initializer] `init(CIImage image: CIImage, options: [VNImageOption : Any] = [:])`
vision/vnimagerequesthandler/init(ciimage:orientation:options:)-3svy6 [Initializer] `init(ciImage image: CIImage, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])` — Creates a handler to be used for performing requests on Core Image image data of a known orientation.
vision/vnimagerequesthandler/init(ciimage:orientation:options:)-8p8h1 [Initializer] `init(CIImage image: CIImage, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])`
vision/vnimagerequesthandler/init(cmsamplebuffer:depthdata:orientation:options:)-8bjyh [Initializer] `init(cmSampleBuffer sampleBuffer: CMSampleBuffer, depthData: AVDepthData, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])` — Creates a request handler that performs requests on an image in a sample buffer that contains depth data.
vision/vnimagerequesthandler/init(cmsamplebuffer:depthdata:orientation:options:)-yi6q [Initializer] `init(CMSampleBuffer sampleBuffer: CMSampleBuffer, depthData: AVDepthData, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])`
vision/vnimagerequesthandler/init(cmsamplebuffer:options:)-2yodn [Initializer] `init(cmSampleBuffer sampleBuffer: CMSampleBuffer, options: [VNImageOption : Any] = [:])` — Creates a request handler that performs requests on an image contained within a sample buffer.
vision/vnimagerequesthandler/init(cmsamplebuffer:options:)-4mpwd [Initializer] `init(CMSampleBuffer sampleBuffer: CMSampleBuffer, options: [VNImageOption : Any] = [:])`
vision/vnimagerequesthandler/init(cmsamplebuffer:orientation:options:)-335k4 [Initializer] `init(cmSampleBuffer sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])` — Creates a request handler that performs requests on an image of a specified orientation contained within a sample buffer.
vision/vnimagerequesthandler/init(cmsamplebuffer:orientation:options:)-6qeht [Initializer] `init(CMSampleBuffer sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])`
vision/vnimagerequesthandler/init(cvpixelbuffer:depthdata:orientation:options:)-3mj2d [Initializer] `init(cvPixelBuffer pixelBuffer: CVPixelBuffer, depthData: AVDepthData, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])`
vision/vnimagerequesthandler/init(cvpixelbuffer:depthdata:orientation:options:)-3u960 [Initializer] `init(CVPixelBuffer pixelBuffer: CVPixelBuffer, depthData: AVDepthData, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])`
vision/vnimagerequesthandler/init(cvpixelbuffer:options:)-3pee9 [Initializer] `init(CVPixelBuffer pixelBuffer: CVPixelBuffer, options: [VNImageOption : Any] = [:])`
vision/vnimagerequesthandler/init(cvpixelbuffer:options:)-bkd7 [Initializer] `init(cvPixelBuffer pixelBuffer: CVPixelBuffer, options: [VNImageOption : Any] = [:])` — Creates a handler for performing requests on a Core Video pixel buffer.
vision/vnimagerequesthandler/init(cvpixelbuffer:orientation:options:)-160f [Initializer] `init(CVPixelBuffer pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])`
vision/vnimagerequesthandler/init(cvpixelbuffer:orientation:options:)-9fxug [Initializer] `init(cvPixelBuffer pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])` — Creates a handler for performing requests on a Core Video pixel buffer of a known orientation.
vision/vnimagerequesthandler/init(data:options:) [Initializer] `init(data imageData: Data, options: [VNImageOption : Any] = [:])` — Creates a handler to use for performing requests on an image in a data object.
vision/vnimagerequesthandler/init(data:orientation:options:) [Initializer] `init(data imageData: Data, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])` — Creates a handler to use for performing requests on an image of known orientation.
vision/vnimagerequesthandler/init(url:options:)-19t0u [Initializer] `init(URL imageURL: URL, options: [VNImageOption : Any] = [:])`
vision/vnimagerequesthandler/init(url:options:)-4k623 [Initializer] `init(url imageURL: URL, options: [VNImageOption : Any] = [:])` — Creates a handler to be used for performing requests on an image at the specified URL.
vision/vnimagerequesthandler/init(url:orientation:options:)-70nta [Initializer] `init(url imageURL: URL, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])` — Creates a handler to be used for performing requests on an image with known orientation, at the specified URL.
vision/vnimagerequesthandler/init(url:orientation:options:)-ou7m [Initializer] `init(URL imageURL: URL, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])`
vision/vnimagerequesthandler/perform(_:) [Instance Method] `func perform(_ requests: [VNRequest]) throws` — Schedules Vision requests to perform.

vision/vnimagetranslationalignmentobservation [Class] `class VNImageTranslationAlignmentObservation` — Affine transform information that an image-alignment request produces.
vision/vnimagetranslationalignmentobservation/alignmenttransform [Instance Property] `var alignmentTransform: CGAffineTransform { get }` — The alignment transform to align the floating image with the reference image.

vision/vninstancemaskobservation [Class] `class VNInstanceMaskObservation` — An observation that contains an instance mask that labels instances in the mask.
vision/vninstancemaskobservation/allinstances [Instance Property] `var allInstances: IndexSet { get }` — The collection that contains all instances, excluding the background.
vision/vninstancemaskobservation/generatemask(forinstances:) [Instance Method] `func generateMask(forInstances instances: IndexSet) throws -> CVPixelBuffer` — Creates a low-resolution mask from the instances you specify.
vision/vninstancemaskobservation/generatemaskedimage(ofinstances:from:croppedtoinstancesextent:) [Instance Method] `func generateMaskedImage(ofInstances instances: IndexSet, from requestHandler: VNImageRequestHandler, croppedToInstancesExtent cropResult: Bool) throws -> CVPixelBuffer` — Creates a high-resolution image where everything becomes transparent black, except for the instances you specify.
vision/vninstancemaskobservation/generatescaledmaskforimage(forinstances:from:) [Instance Method] `func generateScaledMaskForImage(forInstances instances: IndexSet, from requestHandler: VNImageRequestHandler) throws -> CVPixelBuffer` — Creates a high-resolution mask where everything becomes transparent black, except for the instances you specify.
vision/vninstancemaskobservation/instancemask [Instance Property] `var instanceMask: CVPixelBuffer { get }` — The resulting mask that represents all instances.

vision/vnnormalizedfaceboundingboxpointforlandmarkpoint(_:_:_:_:) [Function] `func VNNormalizedFaceBoundingBoxPointForLandmarkPoint(_ faceLandmarkPoint: vector_float2, _ faceBoundingBox: CGRect, _ imageWidth: Int, _ imageHeight: Int) -> CGPoint` — Returns the coordinates of a specified face landmark point, in bounding box coordinates.

vision/vnnormalizedidentityrect [Global Variable] `let VNNormalizedIdentityRect: CGRect` — A normalized identity rectangle with an origin of zero and unit length and width.

vision/vnnormalizedpointforimagepoint(_:_:_:) [Function] `func VNNormalizedPointForImagePoint(_ imagePoint: CGPoint, _ imageWidth: Int, _ imageHeight: Int) -> CGPoint` — Projects a point from image coordinates into normalized coordinates.

vision/vnnormalizedpointforimagepointusingregionofinterest(_:_:_:_:) [Function] `func VNNormalizedPointForImagePointUsingRegionOfInterest(_ imagePoint: CGPoint, _ imageWidth: Int, _ imageHeight: Int, _ roi: CGRect) -> CGPoint` — Projects a point from a region of interest within the image coordinates into normalized coordinates.

vision/vnnormalizedrectforimagerect(_:_:_:) [Function] `func VNNormalizedRectForImageRect(_ imageRect: CGRect, _ imageWidth: Int, _ imageHeight: Int) -> CGRect` — Projects a rectangle from image coordinates into normalized coordinates.

vision/vnnormalizedrectforimagerectusingregionofinterest(_:_:_:_:) [Function] `func VNNormalizedRectForImageRectUsingRegionOfInterest(_ imageRect: CGRect, _ imageWidth: Int, _ imageHeight: Int, _ roi: CGRect) -> CGRect` — Projects a rectangle from a region of interest within the image coordinates space into normalized coordinates.

vision/vnnormalizedrectisidentityrect(_:) [Function] `func VNNormalizedRectIsIdentityRect(_ normalizedRect: CGRect) -> Bool` — Returns a Boolean value that indicates whether the rectangle has an origin of zero and unit length and width.

vision/vnobservation [Class] `class VNObservation` — The abstract superclass for analysis results.
vision/vnobservation/confidence [Instance Property] `var confidence: VNConfidence { get }` — The level of confidence in the observation’s accuracy.
vision/vnobservation/init(coder:) [Initializer] `init?(coder: NSCoder)`
vision/vnobservation/timerange [Instance Property] `var timeRange: CMTimeRange { get }` — The time range of the reported observation.
vision/vnobservation/uuid [Instance Property] `var uuid: UUID { get }` — A unique identifier assigned to the Vision observation.

vision/vnpixelbufferobservation [Class] `class VNPixelBufferObservation` — An object that represents an image that an image-analysis request produces.
vision/vnpixelbufferobservation/featurename [Instance Property] `var featureName: String? { get }` — A feature name that the CoreML model defines.
vision/vnpixelbufferobservation/pixelbuffer [Instance Property] `var pixelBuffer: CVPixelBuffer { get }` — The image that results from a request with image output.

vision/vnpoint [Class] `class VNPoint` — An immutable object that represents a single 2D point in an image.
vision/vnpoint/apply(_:to:) [Type Method] `class func apply(_ vector: VNVector, to point: VNPoint) -> VNPoint` — Creates a point object that’s shifted by the X and Y offsets of the specified vector.
vision/vnpoint/distance(_:) [Instance Method] `func distance(_ point: VNPoint) -> Double` — Returns the distance to another point.
vision/vnpoint/distance(_:_:) [Type Method, deprecated] `class func distance(_ point1: VNPoint, _ point2: VNPoint) -> Double` — Calculates the distance between two points.
vision/vnpoint/init(coder:) [Initializer] `init?(coder: NSCoder)`
vision/vnpoint/init(location:) [Initializer] `convenience init(location: CGPoint)` — Creates a point object from the specified Core Graphics point.
vision/vnpoint/init(x:y:) [Initializer] `init(x: Double, y: Double)` — Creates a point object with the specified coordinates.
vision/vnpoint/location [Instance Property] `var location: CGPoint { get }` — The Core Graphics point for this point.
vision/vnpoint/x [Instance Property] `var x: Double { get }` — The x-coordinate.
vision/vnpoint/y [Instance Property] `var y: Double { get }` — The y-coordinate.
vision/vnpoint/zero [Type Property] `class var zero: VNPoint { get }` — A point object that represents the origin.

vision/vnpoint3d [Class] `class VNPoint3D` — An object that represents a 3D point in an image.
vision/vnpoint3d/init(coder:) [Initializer] `init?(coder: NSCoder)`
vision/vnpoint3d/init(position:) [Initializer] `init?(position: simd_float4x4)` — Creates a point object with the position you specify.
vision/vnpoint3d/position [Instance Property] `var position: simd_float4x4 { get }` — The three-dimensional position.

vision/vnpointsclassification [Enumeration] `@frozen enum VNPointsClassification` — The set of classifications that describe how to interpret the points the region provides.
vision/vnpointsclassification/closedpath [Case] `case closedPath`
vision/vnpointsclassification/disconnected [Case] `case disconnected`
vision/vnpointsclassification/init(rawvalue:) [Initializer] `init?(rawValue: Int)`
vision/vnpointsclassification/openpath [Case] `case openPath`

vision/vnrecognizeanimalsrequest [Class] `class VNRecognizeAnimalsRequest` — A request that recognizes animals in an image.
vision/vnrecognizeanimalsrequest/knownanimalidentifiers(forrevision:) [Type Method, deprecated] `class func knownAnimalIdentifiers(forRevision requestRevision: Int) throws -> [VNAnimalIdentifier]` — Returns a list of animal identifiers the recognition algorithm supports for the specified revision.
vision/vnrecognizeanimalsrequest/results [Instance Property] `var results: [VNRecognizedObjectObservation]? { get }` — The results of the request to recognize animals.
vision/vnrecognizeanimalsrequest/supportedidentifiers() [Instance Method] `func supportedIdentifiers() throws -> [VNAnimalIdentifier]` — Returns the identifiers of the animals that the request detects.

vision/vnrecognizeanimalsrequestrevision1 [Global Variable] `var VNRecognizeAnimalsRequestRevision1: Int { get }` — A constant for specifying revision 1 of the animal recognition request.

vision/vnrecognizeanimalsrequestrevision2 [Global Variable] `var VNRecognizeAnimalsRequestRevision2: Int { get }` — A constant for specifying revision 2 of the animal recognition request.

vision/vnrecognizedobjectobservation [Class] `class VNRecognizedObjectObservation` — A detected object observation with an array of classification labels that classify the recognized object.
vision/vnrecognizedobjectobservation/labels [Instance Property] `var labels: [VNClassificationObservation] { get }` — An array of observations that classify the recognized object.

vision/vnrecognizedpoint [Class] `class VNRecognizedPoint` — An object that represents a normalized point in an image, along with an identifier label and a confidence value.
vision/vnrecognizedpoint/identifier [Instance Property] `var identifier: VNRecognizedPointKey { get }` — The point’s identifier label.

vision/vnrecognizedpoint3d [Class] `class VNRecognizedPoint3D` — A 3D point that includes an identifier to the point.
vision/vnrecognizedpoint3d/identifier [Instance Property] `var identifier: VNRecognizedPointKey { get }` — The identifier that provides context about what kind of point the request recognizes.

vision/vnrecognizedpointgroupkey [Structure] `struct VNRecognizedPointGroupKey` — The data type for all recognized-point group keys.
vision/vnrecognizedpointgroupkey/all [Type Property] `static let all: VNRecognizedPointGroupKey` — A group key identifying all landmarks.
vision/vnrecognizedpointgroupkey/bodylandmarkregionkeyface [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointsGroupName.face)] `static let bodyLandmarkRegionKeyFace: VNRecognizedPointGroupKey` — A group key identifying the face, which includes the eyes, ears, and nose.
vision/vnrecognizedpointgroupkey/bodylandmarkregionkeyleftarm [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointsGroupName.leftArm)] `static let bodyLandmarkRegionKeyLeftArm: VNRecognizedPointGroupKey` — A group key identifying the landmarks of the left arm.
vision/vnrecognizedpointgroupkey/bodylandmarkregionkeyleftleg [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointsGroupName.leftLeg)] `static let bodyLandmarkRegionKeyLeftLeg: VNRecognizedPointGroupKey` — A group key identifying the landmarks of the left leg.
vision/vnrecognizedpointgroupkey/bodylandmarkregionkeyrightarm [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointsGroupName.rightArm)] `static let bodyLandmarkRegionKeyRightArm: VNRecognizedPointGroupKey` — A group key identifying the landmarks of the right arm.
vision/vnrecognizedpointgroupkey/bodylandmarkregionkeyrightleg [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointsGroupName.rightLeg)] `static let bodyLandmarkRegionKeyRightLeg: VNRecognizedPointGroupKey` — A group key identifying the landmarks of the right leg.
vision/vnrecognizedpointgroupkey/bodylandmarkregionkeytorso [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointsGroupName.torso)] `static let bodyLandmarkRegionKeyTorso: VNRecognizedPointGroupKey` — A group key identifying the torso, which includes the neck, shoulders, hips, and root.
vision/vnrecognizedpointgroupkey/init(rawvalue:) [Initializer] `init(rawValue: String)` — Creates a recognized point key with a string value.
vision/vnrecognizedpointgroupkey/point3dgroupkeyall [Type Property] `static let point3DGroupKeyAll: VNRecognizedPointGroupKey` — A group key identifying all three-dimensional landmarks.

vision/vnrecognizedpointkey [Structure] `struct VNRecognizedPointKey` — The data type for all recognized point keys.
vision/vnrecognizedpointkey/bodylandmarkkeyleftankle [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftAnkle)] `static let bodyLandmarkKeyLeftAnkle: VNRecognizedPointKey` — The left ankle.
vision/vnrecognizedpointkey/bodylandmarkkeyleftear [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftEar)] `static let bodyLandmarkKeyLeftEar: VNRecognizedPointKey` — The left ear.
vision/vnrecognizedpointkey/bodylandmarkkeyleftelbow [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftElbow)] `static let bodyLandmarkKeyLeftElbow: VNRecognizedPointKey` — The left elbow.
vision/vnrecognizedpointkey/bodylandmarkkeylefteye [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftEye)] `static let bodyLandmarkKeyLeftEye: VNRecognizedPointKey` — The left eye.
vision/vnrecognizedpointkey/bodylandmarkkeylefthip [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftHip)] `static let bodyLandmarkKeyLeftHip: VNRecognizedPointKey` — The left hip.
vision/vnrecognizedpointkey/bodylandmarkkeyleftknee [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftKnee)] `static let bodyLandmarkKeyLeftKnee: VNRecognizedPointKey` — The left knee.
vision/vnrecognizedpointkey/bodylandmarkkeyleftshoulder [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftShoulder)] `static let bodyLandmarkKeyLeftShoulder: VNRecognizedPointKey` — The left shoulder.
vision/vnrecognizedpointkey/bodylandmarkkeyleftwrist [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftWrist)] `static let bodyLandmarkKeyLeftWrist: VNRecognizedPointKey` — The left wrist.
vision/vnrecognizedpointkey/bodylandmarkkeyneck [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.neck)] `static let bodyLandmarkKeyNeck: VNRecognizedPointKey` — The center point of the neck.
vision/vnrecognizedpointkey/bodylandmarkkeynose [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.nose)] `static let bodyLandmarkKeyNose: VNRecognizedPointKey` — The nose.
vision/vnrecognizedpointkey/bodylandmarkkeyrightankle [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightAnkle)] `static let bodyLandmarkKeyRightAnkle: VNRecognizedPointKey` — The right ankle.
vision/vnrecognizedpointkey/bodylandmarkkeyrightear [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightEar)] `static let bodyLandmarkKeyRightEar: VNRecognizedPointKey` — The right ear.
vision/vnrecognizedpointkey/bodylandmarkkeyrightelbow [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightElbow)] `static let bodyLandmarkKeyRightElbow: VNRecognizedPointKey` — The right elbow.
vision/vnrecognizedpointkey/bodylandmarkkeyrighteye [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightEye)] `static let bodyLandmarkKeyRightEye: VNRecognizedPointKey` — The right eye.
vision/vnrecognizedpointkey/bodylandmarkkeyrighthip [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightHip)] `static let bodyLandmarkKeyRightHip: VNRecognizedPointKey` — The right hip.
vision/vnrecognizedpointkey/bodylandmarkkeyrightknee [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightKnee)] `static let bodyLandmarkKeyRightKnee: VNRecognizedPointKey` — The right knee.
vision/vnrecognizedpointkey/bodylandmarkkeyrightshoulder [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightShoulder)] `static let bodyLandmarkKeyRightShoulder: VNRecognizedPointKey` — The right shoulder.
vision/vnrecognizedpointkey/bodylandmarkkeyrightwrist [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightWrist)] `static let bodyLandmarkKeyRightWrist: VNRecognizedPointKey` — The right wrist.
vision/vnrecognizedpointkey/bodylandmarkkeyroot [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.root)] `static let bodyLandmarkKeyRoot: VNRecognizedPointKey` — The center point of the waist.
vision/vnrecognizedpointkey/init(rawvalue:) [Initializer] `init(rawValue: String)` — Creates a recognized point key with a string value.

vision/vnrecognizedpoints3dobservation [Class] `class VNRecognizedPoints3DObservation` — An observation that provides the 3D points for a request.
vision/vnrecognizedpoints3dobservation/availablegroupkeys [Instance Property] `var availableGroupKeys: [VNRecognizedPointGroupKey] { get }` — The available point group keys in the observation.
vision/vnrecognizedpoints3dobservation/availablekeys [Instance Property] `var availableKeys: [VNRecognizedPointKey] { get }` — The available point keys in the observation.
vision/vnrecognizedpoints3dobservation/recognizedpoint(forkey:) [Instance Method] `func recognizedPoint(forKey pointKey: VNRecognizedPointKey) throws -> VNRecognizedPoint3D` — Returns a point for a key you specify.
vision/vnrecognizedpoints3dobservation/recognizedpoints(forgroupkey:) [Instance Method] `func recognizedPoints(forGroupKey groupKey: VNRecognizedPointGroupKey) throws -> [VNRecognizedPointKey : VNRecognizedPoint3D]` — Returns a point for a group key you specify.

vision/vnrecognizedpointsobservation [Class] `class VNRecognizedPointsObservation` — An observation that provides the points the analysis recognized.
vision/vnrecognizedpointsobservation/availablegroupkeys [Instance Property] `var availableGroupKeys: [VNRecognizedPointGroupKey] { get }` — The available point group keys in the observation.
vision/vnrecognizedpointsobservation/availablekeys [Instance Property] `var availableKeys: [VNRecognizedPointKey] { get }` — The available point keys in the observation.
vision/vnrecognizedpointsobservation/keypointsmultiarray() [Instance Method] `func keypointsMultiArray() throws -> MLMultiArray` — Retrieves the grouping of normalized point coordinates and confidence scores in a format compatible with Core ML.
vision/vnrecognizedpointsobservation/recognizedpoint(forkey:) [Instance Method] `func recognizedPoint(forKey pointKey: VNRecognizedPointKey) throws -> VNRecognizedPoint` — Retrieves a recognized point for a key.
vision/vnrecognizedpointsobservation/recognizedpoints(forgroupkey:) [Instance Method] `func recognizedPoints(forGroupKey groupKey: VNRecognizedPointGroupKey) throws -> [VNRecognizedPointKey : VNRecognizedPoint]` — Retrieves the recognized points for a key.

vision/vnrecognizedtext [Class] `class VNRecognizedText` — Text recognized in an image through a text recognition request.
vision/vnrecognizedtext/boundingbox(for:) [Instance Method] `@nonobjc func boundingBox(for range: Range<String.Index>) throws -> VNRectangleObservation?` — Calculates the bounding box around the characters in the range of a string.
vision/vnrecognizedtext/confidence [Instance Property] `var confidence: VNConfidence { get }` — A normalized confidence score for the text recognition result.
vision/vnrecognizedtext/init(coder:) [Initializer] `init?(coder: NSCoder)`
vision/vnrecognizedtext/string [Instance Property] `var string: String { get }` — The top candidate for recognized text.

vision/vnrecognizedtextobservation [Class] `class VNRecognizedTextObservation` — A request that detects and recognizes regions of text in an image.
vision/vnrecognizedtextobservation/topcandidates(_:) [Instance Method] `func topCandidates(_ maxCandidateCount: Int) -> [VNRecognizedText]` — Requests the *n* top candidates for a recognized text string.

vision/vnrecognizetextrequest [Class] `class VNRecognizeTextRequest` — An image-analysis request that finds and recognizes text in an image.
vision/vnrecognizetextrequest/automaticallydetectslanguage [Instance Property] `var automaticallyDetectsLanguage: Bool { get set }` — A Boolean value that indicates whether to attempt detecting the language to use the appropriate model for recognition and language correction.
vision/vnrecognizetextrequest/customwords [Instance Property] `var customWords: [String] { get set }` — An array of strings to supplement the recognized languages at the word-recognition stage.
vision/vnrecognizetextrequest/minimumtextheight [Instance Property] `var minimumTextHeight: Float { get set }` — The minimum height, relative to the image height, of the text to recognize.
vision/vnrecognizetextrequest/recognitionlanguages [Instance Property] `var recognitionLanguages: [String] { get set }` — An array of languages to detect, in priority order.
vision/vnrecognizetextrequest/recognitionlevel [Instance Property] `var recognitionLevel: VNRequestTextRecognitionLevel { get set }` — A value that determines whether the request prioritizes accuracy or speed in text recognition.
vision/vnrecognizetextrequest/results [Instance Property] `var results: [VNRecognizedTextObservation]? { get }` — The results of the text recognition request.
vision/vnrecognizetextrequest/supportedrecognitionlanguages() [Instance Method] `func supportedRecognitionLanguages() throws -> [String]` — Returns the identifiers of the languages that the request supports.
vision/vnrecognizetextrequest/supportedrecognitionlanguages(for:revision:) [Type Method, deprecated] `class func supportedRecognitionLanguages(for recognitionLevel: VNRequestTextRecognitionLevel, revision requestRevision: Int) throws -> [String]` — Requests a list of languages that the specified revision recognizes.
vision/vnrecognizetextrequest/useslanguagecorrection [Instance Property] `var usesLanguageCorrection: Bool { get set }` — A Boolean value that indicates whether the request applies language correction during the recognition process.

vision/vnrecognizetextrequestrevision1 [Global Variable, deprecated (renamed: VNRecognizeTextRequestRevision3)] `var VNRecognizeTextRequestRevision1: Int { get }` — A constant for specifying revision 1 of the text recognition request.

vision/vnrecognizetextrequestrevision2 [Global Variable, deprecated (renamed: VNRecognizeTextRequestRevision3)] `var VNRecognizeTextRequestRevision2: Int { get }` — A constant for specifying revision 2 of the text recognition request.

vision/vnrecognizetextrequestrevision3 [Global Variable] `var VNRecognizeTextRequestRevision3: Int { get }` — A constant for specifying revision 3 of the text recognition request.

vision/vnrectangleobservation [Class] `class VNRectangleObservation` — An object that represents the four vertices of a detected rectangle.
vision/vnrectangleobservation/bottomleft [Instance Property] `var bottomLeft: CGPoint { get }` — The coordinates of the lower-left corner of the observation bounding box.
vision/vnrectangleobservation/bottomright [Instance Property] `var bottomRight: CGPoint { get }` — The coordinates of the lower-right corner of the observation bounding box.
vision/vnrectangleobservation/init(requestrevision:topleft:bottomleft:bottomright:topright:) [Initializer, deprecated] `convenience init(requestRevision: Int, topLeft: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint, topRight: CGPoint)` — Creates a rectangle observation from its corner points.
vision/vnrectangleobservation/init(requestrevision:topleft:topright:bottomright:bottomleft:) [Initializer] `convenience init(requestRevision: Int, topLeft: CGPoint, topRight: CGPoint, bottomRight: CGPoint, bottomLeft: CGPoint)` — Creates a rectangle observation from its corner points.
vision/vnrectangleobservation/topleft [Instance Property] `var topLeft: CGPoint { get }` — The coordinates of the upper-left corner of the observation bounding box.
vision/vnrectangleobservation/topright [Instance Property] `var topRight: CGPoint { get }` — The coordinates of the upper-right corner of the observation bounding box.

vision/vnrequest [Class] `class VNRequest` — The abstract superclass for analysis requests.
vision/vnrequest/cancel() [Instance Method] `func cancel()` — Cancels the request before it can finish executing.
vision/vnrequest/completionhandler [Instance Property] `var completionHandler: VNRequestCompletionHandler? { get }` — The completion handler the system invokes after the request finishes processing.
vision/vnrequest/computedevice(for:) [Instance Method] `@nonobjc func computeDevice(for computeStage: VNComputeStage) -> MLComputeDevice?` — Returns the compute device for a compute stage.
vision/vnrequest/currentrevision [Type Property] `class var currentRevision: Int { get }` — The current revison supported by the request.
vision/vnrequest/defaultrevision [Type Property] `class var defaultRevision: Int { get }` — The revision of the latest request for the particular SDK linked with the client application.
vision/vnrequest/init() [Initializer] `convenience init()` — Creates a new Vision request with no completion handler.
vision/vnrequest/init(completionhandler:) [Initializer] `init(completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new Vision request with an optional completion handler.
vision/vnrequest/preferbackgroundprocessing [Instance Property] `var preferBackgroundProcessing: Bool { get set }` — A hint to minimize the resource burden of the request.
vision/vnrequest/results [Instance Property] `var results: [VNObservation]? { get }` — The collection of observation results generated by request processing.
vision/vnrequest/revision [Instance Property] `var revision: Int { get set }` — The specific algorithm or implementation revision that’s used to perform the request.
vision/vnrequest/setcomputedevice(_:for:) [Instance Method] `@nonobjc func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: VNComputeStage)` — Assigns a compute device for a compute stage.
vision/vnrequest/supportedcomputestagedevices [Instance Property] `@nonobjc var supportedComputeStageDevices: [VNComputeStage : [MLComputeDevice]] { get throws }` — The collection of compute devices per stage that a request supports.
vision/vnrequest/supportedrevisions [Type Property] `class var supportedRevisions: IndexSet { get }` — The collection of currently-supported algorithm versions for the class of request.
vision/vnrequest/usescpuonly [Instance Property, deprecated] `var usesCPUOnly: Bool { get set }` — A Boolean signifying that the Vision request should execute exclusively on the CPU.

vision/vnrequestcompletionhandler [Type Alias] `typealias VNRequestCompletionHandler = (VNRequest, (any Error)?) -> Void` — A type alias to encapsulate the syntax for the completion handler the system calls after the request finishes processing.

vision/vnrequestfacelandmarksconstellation [Enumeration] `enum VNRequestFaceLandmarksConstellation` — An enumeration of face landmarks in a constellation object.
vision/vnrequestfacelandmarksconstellation/constellation65points [Case] `case constellation65Points` — A constellation with 65 points.
vision/vnrequestfacelandmarksconstellation/constellation76points [Case] `case constellation76Points` — A constellation with 76 points.
vision/vnrequestfacelandmarksconstellation/constellationnotdefined [Case] `case constellationNotDefined` — An undefined constellation.
vision/vnrequestfacelandmarksconstellation/init(rawvalue:) [Initializer] `init?(rawValue: UInt)`

vision/vnrequestprogresshandler [Type Alias] `typealias VNRequestProgressHandler = (VNRequest, Double, (any Error)?) -> Void` — A block executed at intervals during the processing of a Vision request.

vision/vnrequestprogressproviding [Protocol] `protocol VNRequestProgressProviding : NSObjectProtocol` — A protocol for providing progress information on long-running tasks in Vision.
vision/vnrequestprogressproviding/indeterminate [Instance Property] `var indeterminate: Bool { get }` — A Boolean set to true when a request can’t determine its progress in fractions completed.
vision/vnrequestprogressproviding/progresshandler [Instance Property] `var progressHandler: VNRequestProgressHandler { get set }` — A block of code executed periodically during a Vision request to report progress on long-running tasks.

vision/vnrequestrevisionproviding [Protocol] `protocol VNRequestRevisionProviding` — A protocol for specifying the revision number of Vision algorithms.
vision/vnrequestrevisionproviding/requestrevision [Instance Property] `var requestRevision: Int { get }` — The revision of the VNRequest subclass used to generate the implementing object.

vision/vnrequestrevisionunspecified [Global Variable] `var VNRequestRevisionUnspecified: Int { get }` — A constant for specifying an unspecified request revision.

vision/vnrequesttextrecognitionlevel [Enumeration] `enum VNRequestTextRecognitionLevel` — Constants that identify the performance and accuracy of the text recognition.
vision/vnrequesttextrecognitionlevel/accurate [Case] `case accurate` — Accurate text recognition takes more time to produce a more comprehensive result.
vision/vnrequesttextrecognitionlevel/fast [Case] `case fast` — Fast text recognition returns results more quickly at the expense of accuracy.
vision/vnrequesttextrecognitionlevel/init(rawvalue:) [Initializer] `init?(rawValue: Int)`

vision/vnrequesttrackinglevel [Enumeration] `enum VNRequestTrackingLevel` — An enumeration of tracking priorities.
vision/vnrequesttrackinglevel/accurate [Case] `case accurate` — Tracking level that favors location accuracy over speed.
vision/vnrequesttrackinglevel/fast [Case] `case fast` — Tracking level that favors speed over location accuracy.
vision/vnrequesttrackinglevel/init(rawvalue:) [Initializer] `init?(rawValue: UInt)`

vision/vnsaliencyimageobservation [Class] `class VNSaliencyImageObservation` — An observation that contains a grayscale heat map of important areas across an image.
vision/vnsaliencyimageobservation/salientobjects [Instance Property] `var salientObjects: [VNRectangleObservation]? { get }` — A collection of objects describing the distinct areas of the saliency heat map.

vision/vnsequencerequesthandler [Class] `class VNSequenceRequestHandler` — An object that processes image-analysis requests for each frame in a sequence.
vision/vnsequencerequesthandler/init() [Initializer] `init()` — Initializes a sequence request handler.
vision/vnsequencerequesthandler/perform(_:on:)-3d7nt [Instance Method] `func perform(_ requests: [VNRequest], on pixelBuffer: CVPixelBuffer) throws` — Schedules one or more Vision requests to be performed on a Core Video pixel buffer.
vision/vnsequencerequesthandler/perform(_:on:)-3zt7l [Instance Method] `func perform(_ requests: [VNRequest], on image: CGImage) throws` — Schedules Vision requests to be performed on a Core Graphics image.
vision/vnsequencerequesthandler/perform(_:on:)-45e73 [Instance Method] `func perform(_ requests: [VNRequest], on sampleBuffer: CMSampleBuffer) throws` — Performs one or more requests on an image contained within a sample buffer.
vision/vnsequencerequesthandler/perform(_:on:)-9jtgj [Instance Method] `func perform(_ requests: [VNRequest], on image: CIImage) throws` — Schedules one or more Vision requests to be performed on Core Image image data.
vision/vnsequencerequesthandler/perform(_:on:orientation:)-1bkm1 [Instance Method] `func perform(_ requests: [VNRequest], on image: CIImage, orientation: CGImagePropertyOrientation) throws` — Schedules one or more Vision requests to be performed on Core Image image data with known orientation.
vision/vnsequencerequesthandler/perform(_:on:orientation:)-2wvt8 [Instance Method] `func perform(_ requests: [VNRequest], on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) throws` — Schedules one or more Vision requests to be performed on a Core Video pixel buffer with known orientation.
vision/vnsequencerequesthandler/perform(_:on:orientation:)-3gcmv [Instance Method] `func perform(_ requests: [VNRequest], on image: CGImage, orientation: CGImagePropertyOrientation) throws` — Schedules one or more Vision requests to be performed on a Core Graphics image with known orientation.
vision/vnsequencerequesthandler/perform(_:on:orientation:)-6b7rk [Instance Method] `func perform(_ requests: [VNRequest], on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) throws` — Performs one or more requests on an image of a specified orientation contained within a sample buffer.
vision/vnsequencerequesthandler/perform(_:onimagedata:) [Instance Method] `func perform(_ requests: [VNRequest], onImageData imageData: Data) throws` — Schedules one or more Vision requests to be performed on raw image data.
vision/vnsequencerequesthandler/perform(_:onimagedata:orientation:) [Instance Method] `func perform(_ requests: [VNRequest], onImageData imageData: Data, orientation: CGImagePropertyOrientation) throws` — Schedules one or more Vision requests to be performed on raw data containing an image with known orientation.
vision/vnsequencerequesthandler/perform(_:onimageurl:) [Instance Method] `func perform(_ requests: [VNRequest], onImageURL imageURL: URL) throws` — Schedules one or more Vision requests to be performed on an image.
vision/vnsequencerequesthandler/perform(_:onimageurl:orientation:) [Instance Method] `func perform(_ requests: [VNRequest], onImageURL imageURL: URL, orientation: CGImagePropertyOrientation) throws` — Schedules one or more Vision requests to be performed on an image with known orientation, at a specific URL.

vision/vnstatefulrequest [Class] `class VNStatefulRequest` — An abstract request type that builds evidence of a condition over time.
vision/vnstatefulrequest/frameanalysisspacing [Instance Property] `var frameAnalysisSpacing: CMTime { get }` — A time value that indicates the interval between analysis operations.
vision/vnstatefulrequest/init(frameanalysisspacing:completionhandler:) [Initializer] `init(frameAnalysisSpacing: CMTime, completionHandler: VNRequestCompletionHandler? = nil)` — Initializes a video-based request.
vision/vnstatefulrequest/minimumlatencyframecount [Instance Property] `var minimumLatencyFrameCount: Int { get }` — The minimum number of frames a request processes before reporting an observation.

vision/vntargetedimagerequest [Class] `class VNTargetedImageRequest` — The abstract superclass for image analysis requests that operate on both the processed image and a secondary image.
vision/vntargetedimagerequest/init(targetedcgimage:options:completionhandler:) [Initializer] `init(targetedCGImage cgImage: CGImage, options: [VNImageOption : Any] = [:], completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request targeting a Core Graphics image, executing the completion handler when done.
vision/vntargetedimagerequest/init(targetedcgimage:orientation:options:completionhandler:) [Initializer] `init(targetedCGImage cgImage: CGImage, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:], completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request targeting a Core Graphics image of known orientation, executing the completion handler when done.
vision/vntargetedimagerequest/init(targetedciimage:options:completionhandler:) [Initializer] `init(targetedCIImage ciImage: CIImage, options: [VNImageOption : Any] = [:], completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request targeting a Core Image image.
vision/vntargetedimagerequest/init(targetedciimage:orientation:options:completionhandler:) [Initializer] `init(targetedCIImage ciImage: CIImage, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:], completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request targeting a Core Image image of known orientation, executing the completion handler when done.
vision/vntargetedimagerequest/init(targetedcmsamplebuffer:options:completionhandler:) [Initializer] `init(targetedCMSampleBuffer sampleBuffer: CMSampleBuffer, options: [VNImageOption : Any] = [:], completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request with a completion handler that targets an image in a sample buffer.
vision/vntargetedimagerequest/init(targetedcmsamplebuffer:orientation:options:completionhandler:) [Initializer] `init(targetedCMSampleBuffer sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:], completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request with a completion handler that targets an image of a known orientation in a sample buffer.
vision/vntargetedimagerequest/init(targetedcvpixelbuffer:options:completionhandler:) [Initializer] `init(targetedCVPixelBuffer pixelBuffer: CVPixelBuffer, options: [VNImageOption : Any] = [:], completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request targeting an image in a pixel buffer.
vision/vntargetedimagerequest/init(targetedcvpixelbuffer:orientation:options:completionhandler:) [Initializer] `init(targetedCVPixelBuffer pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:], completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request targeting an image in a pixel buffer of known orientation.
vision/vntargetedimagerequest/init(targetedimagedata:options:completionhandler:) [Initializer] `init(targetedImageData imageData: Data, options: [VNImageOption : Any] = [:], completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request targeting an image as raw data, executing the completion handler when done.
vision/vntargetedimagerequest/init(targetedimagedata:orientation:options:completionhandler:) [Initializer] `init(targetedImageData imageData: Data, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:], completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request targeting a raw data image of known orientation, executing the completion handler when done.
vision/vntargetedimagerequest/init(targetedimageurl:options:completionhandler:) [Initializer] `init(targetedImageURL imageURL: URL, options: [VNImageOption : Any] = [:], completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request targeting an image at the specified URL, executing the completion handler when done.
vision/vntargetedimagerequest/init(targetedimageurl:orientation:options:completionhandler:) [Initializer] `init(targetedImageURL imageURL: URL, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:], completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request targeting an image of known orientation, at the specified URL, executing the completion handler when done.

vision/vntextobservation [Class] `class VNTextObservation` — Information about regions of text that an image-analysis request detects.
vision/vntextobservation/characterboxes [Instance Property] `var characterBoxes: [VNRectangleObservation]? { get }` — An array of detected individual character bounding boxes.

vision/vntrackhomographicimageregistrationrequest [Class] `class VNTrackHomographicImageRegistrationRequest` — An image-analysis request, as a stateful request you track over time, that determines the perspective warp matrix necessary to align the content of two images.
vision/vntrackhomographicimageregistrationrequest/init() [Initializer] `init()` — Creates a new request that tracks the homographic transformation of two images.
vision/vntrackhomographicimageregistrationrequest/init(completionhandler:) [Initializer] `init(completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request that tracks the homographic transformation of two images, with a system callback on completion.
vision/vntrackhomographicimageregistrationrequest/results [Instance Property] `var results: [VNImageHomographicAlignmentObservation]? { get }` — The observed homographic image alignment request.

vision/vntrackhomographicimageregistrationrequestrevision1 [Global Variable] `var VNTrackHomographicImageRegistrationRequestRevision1: Int { get }` — A value that indicates the first revision for a homographic image-registration request.

vision/vntrackingrequest [Class] `class VNTrackingRequest` — The abstract superclass for image-analysis requests that track unique features across multiple images or video frames.
vision/vntrackingrequest/inputobservation [Instance Property] `var inputObservation: VNDetectedObjectObservation { get set }` — The observation object defining a region to track.
vision/vntrackingrequest/islastframe [Instance Property] `var isLastFrame: Bool { get set }` — A Boolean that indicates the last frame in a tracking sequence.
vision/vntrackingrequest/supportednumber(oftrackersandreturnerror:) [Instance Method] `func supportedNumber(ofTrackersAndReturnError error: NSErrorPointer) -> Int` — Returns the maximum number of simultaneous trackers for the request.
vision/vntrackingrequest/trackinglevel [Instance Property] `var trackingLevel: VNRequestTrackingLevel { get set }` — A value for specifying whether to prioritize speed or location accuracy.

vision/vntrackobjectrequest [Class] `class VNTrackObjectRequest` — An image-analysis request that tracks the movement of a previously identified object across multiple images or video frames.
vision/vntrackobjectrequest/init(detectedobjectobservation:) [Initializer] `init(detectedObjectObservation observation: VNDetectedObjectObservation)` — Creates a new object tracking request with a detected object observation.
vision/vntrackobjectrequest/init(detectedobjectobservation:completionhandler:) [Initializer] `init(detectedObjectObservation observation: VNDetectedObjectObservation, completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new object tracking request with a detected object observation.

vision/vntrackobjectrequestrevision1 [Global Variable] `var VNTrackObjectRequestRevision1: Int { get }` — A constant for specifying revision 1 of the object tracking request.

vision/vntrackobjectrequestrevision2 [Global Variable] `var VNTrackObjectRequestRevision2: Int { get }` — A constant for specifying revision 2 of the object tracking request.

vision/vntrackopticalflowrequest [Class] `class VNTrackOpticalFlowRequest` — An object that determines the direction change of vectors for each pixel from a previous to current image.
vision/vntrackopticalflowrequest/computationaccuracy-swift.enum [Enumeration] `enum ComputationAccuracy` — Computational accuracy options.
vision/vntrackopticalflowrequest/computationaccuracy-swift.enum/high [Case] `case high` — An option that indicates a high level of computational accuracy.
vision/vntrackopticalflowrequest/computationaccuracy-swift.enum/init(rawvalue:) [Initializer] `init?(rawValue: UInt)`
vision/vntrackopticalflowrequest/computationaccuracy-swift.enum/low [Case] `case low` — An option that indicates a low level of computational accuracy.
vision/vntrackopticalflowrequest/computationaccuracy-swift.enum/medium [Case] `case medium` — An option that indicates a moderate level of computational accuracy.
vision/vntrackopticalflowrequest/computationaccuracy-swift.enum/veryhigh [Case] `case veryHigh` — An option that indicates a very high level of computational accuracy.
vision/vntrackopticalflowrequest/computationaccuracy-swift.property [Instance Property] `var computationAccuracy: VNTrackOpticalFlowRequest.ComputationAccuracy { get set }` — The level of accuracy to compute the optical flow.
vision/vntrackopticalflowrequest/init() [Initializer] `init()` — Creates a new request that tracks the optical from one image to another.
vision/vntrackopticalflowrequest/init(completionhandler:) [Initializer] `init(completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request that tracks the optical from one image to another, with a system callback on completion.
vision/vntrackopticalflowrequest/keepnetworkoutput [Instance Property] `var keepNetworkOutput: Bool { get set }` — A Boolean value that indicates the raw pixel buffer continues to emit from the network.
vision/vntrackopticalflowrequest/outputpixelformat [Instance Property] `var outputPixelFormat: OSType { get set }` — The pixel format type of the output value.
vision/vntrackopticalflowrequest/results [Instance Property] `var results: [VNPixelBufferObservation]? { get }` — The optical flow results the request observes.

vision/vntrackopticalflowrequestrevision1 [Global Variable] `var VNTrackOpticalFlowRequestRevision1: Int { get }` — A value that indicates the first revision for an optial-flow request.

vision/vntrackrectanglerequest [Class] `class VNTrackRectangleRequest` — An image-analysis request that tracks movement of a previously identified rectangular object across multiple images or video frames.
vision/vntrackrectanglerequest/init(rectangleobservation:) [Initializer] `convenience init(rectangleObservation observation: VNRectangleObservation)` — Creates a new rectangle tracking request with a rectangle observation.
vision/vntrackrectanglerequest/init(rectangleobservation:completionhandler:) [Initializer] `init(rectangleObservation observation: VNRectangleObservation, completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new rectangle tracking request with a rectangle observation.

vision/vntrackrectanglerequestrevision1 [Global Variable] `var VNTrackRectangleRequestRevision1: Int { get }` — A constant for specifying revision 1 of the rectangling tracking request.

vision/vntracktranslationalimageregistrationrequest [Class] `class VNTrackTranslationalImageRegistrationRequest` — An image-analysis request, as a stateful request you track over time, that determines the affine transform necessary to align the content of two images.
vision/vntracktranslationalimageregistrationrequest/init() [Initializer] `init()` — Creates a new request that tracks the translational registration of two images.
vision/vntracktranslationalimageregistrationrequest/init(completionhandler:) [Initializer] `init(completionHandler: VNRequestCompletionHandler? = nil)` — Creates a new request that tracks the translational registration of two images, with a system callback on completion.
vision/vntracktranslationalimageregistrationrequest/results [Instance Property] `var results: [VNImageTranslationAlignmentObservation]? { get }` — The observed translational image alignment request.

vision/vntracktranslationalimageregistrationrequestrevision1 [Global Variable] `var VNTrackTranslationalImageRegistrationRequestRevision1: Int { get }` — A value that indicates the first revision for a translational image-registration request.

vision/vntrajectoryobservation [Class] `class VNTrajectoryObservation` — An observation that describes a detected trajectory.
vision/vntrajectoryobservation/detectedpoints [Instance Property] `var detectedPoints: [VNPoint] { get }` — The centroid points of the detected contour along the trajectory.
vision/vntrajectoryobservation/equationcoefficients [Instance Property] `var equationCoefficients: simd_float3 { get }` — The coefficients of the parabolic equation.
vision/vntrajectoryobservation/movingaverageradius [Instance Property] `var movingAverageRadius: CGFloat { get }` — The moving average radius of the object the request is tracking.
vision/vntrajectoryobservation/projectedpoints [Instance Property] `var projectedPoints: [VNPoint] { get }` — The centroids of the calculated trajectory from the detected points.

vision/vntranslationalimageregistrationrequest [Class] `class VNTranslationalImageRegistrationRequest` — An image-analysis request that determines the affine transform necessary to align the content of two images.
vision/vntranslationalimageregistrationrequest/results [Instance Property] `var results: [VNImageTranslationAlignmentObservation]? { get }` — The results of a translational image alignment request.

vision/vntranslationalimageregistrationrequestrevision1 [Global Variable] `var VNTranslationalImageRegistrationRequestRevision1: Int { get }` — A constant for specifying revision 1 of the translational image registration request.

vision/vnvector [Class] `class VNVector` — An immutable 2D vector represented by its x-axis and y-axis projections.
vision/vnvector/dotproduct(of:vector:) [Type Method] `class func dotProduct(of v1: VNVector, vector v2: VNVector) -> Double` — Caclulates the dot product of two vectors.
vision/vnvector/init(byadding:to:) [Initializer] `init(byAdding v1: VNVector, to v2: VNVector)` — Creates a new vector by adding the specified vectors.
vision/vnvector/init(byaddingvector:tovector:) [Initializer] `init(byAddingVector v1: VNVector, toVector v2: VNVector)`
vision/vnvector/init(bymultiplying:byscalar:) [Initializer] `init(byMultiplying vector: VNVector, byScalar scalar: Double)` — Creates a new vector by multiplying the specified vector’s x-axis and y-axis projections by the scalar value.
vision/vnvector/init(bymultiplyingvector:byscalar:) [Initializer] `init(byMultiplyingVector vector: VNVector, byScalar scalar: Double)`
vision/vnvector/init(bysubtracting:from:) [Initializer] `init(bySubtracting v1: VNVector, from v2: VNVector)` — Creates a new vector by subtracting the first vector from the second vector.
vision/vnvector/init(bysubtractingvector:fromvector:) [Initializer] `init(bySubtractingVector v1: VNVector, fromVector v2: VNVector)`
vision/vnvector/init(coder:) [Initializer] `init?(coder: NSCoder)`
vision/vnvector/init(r:theta:) [Initializer] `convenience init(r: Double, theta: Double)` — Creates a new vector in polar coordinate space.
vision/vnvector/init(vectorhead:tail:) [Initializer] `convenience init(vectorHead head: VNPoint, tail: VNPoint)` — Creates a new vector in Cartesian coordinate space.
vision/vnvector/init(xcomponent:ycomponent:)-231pv [Initializer] `init(XComponent x: Double, yComponent y: Double)`
vision/vnvector/init(xcomponent:ycomponent:)-3p5k3 [Initializer] `init(xComponent x: Double, yComponent y: Double)` — Creates a new vector in Cartesian coordinate space, based on its x-axis and y-axis projections.
vision/vnvector/length [Instance Property] `var length: Double { get }` — The length, or absolute value, of the vector.
vision/vnvector/r [Instance Property] `var r: Double { get }` — The radius, absolute value, or length of the vector.
vision/vnvector/squaredlength [Instance Property] `var squaredLength: Double { get }` — The squared length of the vector.
vision/vnvector/theta [Instance Property] `var theta: Double { get }` — The angle between the vector direction and the positive direction of the x-axis.
vision/vnvector/unitvector(for:) [Type Method] `class func unitVector(for vector: VNVector) -> VNVector` — Calculates a vector that’s normalized by preserving its direction, so that the vector length equals 1.0.
vision/vnvector/x [Instance Property] `var x: Double { get }` — A signed projection that indicates the vector’s direction on the x-axis.
vision/vnvector/y [Instance Property] `var y: Double { get }` — A signed projection that indicates the vector’s direction on the y-axis.
vision/vnvector/zero [Type Property] `class var zero: VNVector { get }` — A vector object with zero length.

vision/vnvideoprocessingoption [Structure, deprecated (renamed: VNVideoProcessor.RequestProcessingOptions)] `struct VNVideoProcessingOption` — Options to pass to the video processor when adding requests.
vision/vnvideoprocessingoption/framecadence [Type Property, deprecated (renamed: VNVideoProcessor.RequestProcessingOptions)] `static let frameCadence: VNVideoProcessingOption` — A value that indicates the video frame cadence at which to perform the video processing.
vision/vnvideoprocessingoption/init(rawvalue:) [Initializer, deprecated (renamed: VNVideoProcessor.RequestProcessingOptions)] `init(rawValue: String)` — Creates an option with a string value.
vision/vnvideoprocessingoption/timeinterval [Type Property, deprecated (renamed: VNVideoProcessor.RequestProcessingOptions)] `static let timeInterval: VNVideoProcessingOption` — A value that indicates that the video processor should perform a request every *n*-seconds.

vision/vnvideoprocessor [Class] `class VNVideoProcessor` — An object that performs offline analysis of video content.
vision/vnvideoprocessor/add(_:withprocessingoptions:) [Instance Method, deprecated] `func add(_ request: VNRequest, withProcessingOptions processingOptions: [VNVideoProcessingOption : Any] = [:]) throws` — Adds a Vision request to perform with the specified configuration.
vision/vnvideoprocessor/addrequest(_:processingoptions:) [Instance Method] `func addRequest(_ request: VNRequest, processingOptions: VNVideoProcessor.RequestProcessingOptions) throws` — Adds a request with processing options to the video processor.
vision/vnvideoprocessor/analyze(_:) [Instance Method] `func analyze(_ timeRange: CMTimeRange) throws` — Analyzes a time range of video content.
vision/vnvideoprocessor/analyze(with:) [Instance Method, deprecated] `func analyze(with timeRange: CMTimeRange) throws` — Analyzes the specifed time range of the video content.
vision/vnvideoprocessor/cadence [Class] `class Cadence` — An object that defines the cadence at which to process video.
vision/vnvideoprocessor/cancel() [Instance Method] `func cancel()` — Cancels the video processing.
vision/vnvideoprocessor/frameratecadence [Class] `class FrameRateCadence` — An object that defines a frame-based cadence for processing a video stream.
vision/vnvideoprocessor/frameratecadence/framerate [Instance Property] `var frameRate: Int { get }` — The frame rate at which to process video.
vision/vnvideoprocessor/frameratecadence/init(_:) [Initializer] `init(_ frameRate: Int)` — Creates a new frame-based cadence with a frame rate.
vision/vnvideoprocessor/frameratecadence/init(framerate:) [Initializer] `init(frameRate: Int)`
vision/vnvideoprocessor/init(url:)-38vj9 [Initializer] `init(URL videoURL: URL)`
vision/vnvideoprocessor/init(url:)-94b7 [Initializer] `init(url videoURL: URL)` — Creates a video processor to perform Vision requests against the specified video asset.
vision/vnvideoprocessor/removerequest(_:) [Instance Method] `func removeRequest(_ request: VNRequest) throws` — Removes a Vision request from the video processor’s request queue.
vision/vnvideoprocessor/requestprocessingoptions [Class] `class RequestProcessingOptions` — An object that defines a video processor’s configuration options.
vision/vnvideoprocessor/requestprocessingoptions/cadence [Instance Property] `@NSCopying var cadence: VNVideoProcessor.Cadence? { get set }` — The cadence the video processor maintains to process the request.
vision/vnvideoprocessor/timeintervalcadence [Class] `class TimeIntervalCadence` — An object that defines a time-based cadence for processing a video stream.
vision/vnvideoprocessor/timeintervalcadence/init(_:) [Initializer] `init(_ timeInterval: CFTimeInterval)` — Creates a new time-based cadence with a time interval.
vision/vnvideoprocessor/timeintervalcadence/init(timeinterval:) [Initializer] `init(timeInterval: CFTimeInterval)`
vision/vnvideoprocessor/timeintervalcadence/timeinterval [Instance Property] `var timeInterval: CFTimeInterval { get }` — The time interval of the cadence.

vision/vnvisionversionnumber [Global Variable] `var VNVisionVersionNumber: Double` — The current version number of the Vision framework.
