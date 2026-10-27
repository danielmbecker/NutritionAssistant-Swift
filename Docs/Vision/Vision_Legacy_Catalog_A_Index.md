# Vision Framework — Legacy API Catalog (Option A: Index)

This is a REFERENCE CATALOG of the legacy Vision API (VN* classes, completion-handler
style, iOS 11+), NOT full documentation. It lists every legacy document that was
scraped (902 total), so you can tell what exists and pick the right symbol.

Entry format:  id [kind]
  - id      document id; all ids are under the Vision framework
  - [kind]  symbol kind, plus status markers when they apply:
              deprecated                 Apple has deprecated this symbol
              deprecated (renamed: X)    deprecated; X is Apple's named replacement
              beta                       marked beta
            No marker means the symbol is NOT deprecated. When suggesting code, prefer the
            "renamed" replacement over a deprecated symbol.

A type is followed by its members; blank lines separate top-level symbols.

TO GET THE FULL DOCUMENTATION for any entry, ask the user for it by id, e.g.
"please provide vision/vnrecognizetextrequest/recognitionlevel". The user retrieves
it with:  node get-doc.js <id>

Generated: 2026-10-12T02:03:54.794Z
────────────────────────────────────────────────────────────────────────────────

vision [Framework]

vision/aligning-similar-images [Sample Code]

vision/analyzing-image-similarity-with-feature-print [Sample Code]

vision/applying-matte-effects-to-people-in-images-and-video [Sample Code]

vision/applying-visual-effects-to-foreground-subjects [Sample Code]

vision/body-landmarks [API Collection]

vision/building-a-feature-rich-app-for-sports-analysis [Sample Code]

vision/classifying-images-for-categorization-and-search [Sample Code]

coreml/classifying-images-with-vision-and-core-ml [Sample Code]

vision/cropping-images-using-saliency [Article]

vision/detecting-animal-body-poses-with-vision [Sample Code]

vision/detecting-hand-poses-with-vision [Sample Code]

createml/detecting-human-actions-in-a-live-video-feed [Sample Code]

vision/detecting-human-body-poses-in-3d-with-vision [Sample Code]

vision/detecting-human-body-poses-in-images [Article]

vision/detecting-moving-objects-in-a-video [Sample Code]

vision/detecting-objects-in-still-images [Sample Code]

vision/extracting-phone-numbers-from-text-in-images [Sample Code]

vision/hand-landmarks [API Collection]

vision/highlighting-areas-of-interest-in-an-image-using-saliency [Sample Code]

vision/identifying-3d-human-body-poses-in-images [Article]

vision/identifying-trajectories-in-video [Article]

vision/locating-and-displaying-recognized-text [Sample Code]

vision/original-objective-c-and-swift-api [API Collection]

vision/recognizing-objects-in-live-capture [Sample Code]

vision/recognizing-text-in-images [Article]

vision/segmenting-and-colorizing-individuals-from-a-surrounding-scene [Sample Code]

vision/selecting-a-selfie-based-on-capture-quality [Sample Code]

visionkit/structuring-recognized-text-on-a-document [Sample Code]

vision/tracking-multiple-objects-or-rectangles-in-video [Sample Code]

vision/tracking-the-user-s-face-in-real-time [Sample Code]

vision/training-a-create-ml-model-to-classify-flowers [Sample Code]

coreml/understanding-a-dice-roll-with-vision-and-object-detection [Sample Code]

vision/vision-macros [API Collection]

vision/vnanimalbodyposeobservation [Class]
vision/vnanimalbodyposeobservation/availablejointgroupnames [Instance Property]
vision/vnanimalbodyposeobservation/availablejointnames [Instance Property]
vision/vnanimalbodyposeobservation/jointname [Structure]
vision/vnanimalbodyposeobservation/jointname/init(rawvalue:) [Initializer]
vision/vnanimalbodyposeobservation/jointname/leftbackelbow [Type Property]
vision/vnanimalbodyposeobservation/jointname/leftbackknee [Type Property]
vision/vnanimalbodyposeobservation/jointname/leftbackpaw [Type Property]
vision/vnanimalbodyposeobservation/jointname/leftearbottom [Type Property]
vision/vnanimalbodyposeobservation/jointname/leftearmiddle [Type Property]
vision/vnanimalbodyposeobservation/jointname/lefteartop [Type Property]
vision/vnanimalbodyposeobservation/jointname/lefteye [Type Property]
vision/vnanimalbodyposeobservation/jointname/leftfrontelbow [Type Property]
vision/vnanimalbodyposeobservation/jointname/leftfrontknee [Type Property]
vision/vnanimalbodyposeobservation/jointname/leftfrontpaw [Type Property]
vision/vnanimalbodyposeobservation/jointname/neck [Type Property]
vision/vnanimalbodyposeobservation/jointname/nose [Type Property]
vision/vnanimalbodyposeobservation/jointname/rightbackelbow [Type Property]
vision/vnanimalbodyposeobservation/jointname/rightbackknee [Type Property]
vision/vnanimalbodyposeobservation/jointname/rightbackpaw [Type Property]
vision/vnanimalbodyposeobservation/jointname/rightearbottom [Type Property]
vision/vnanimalbodyposeobservation/jointname/rightearmiddle [Type Property]
vision/vnanimalbodyposeobservation/jointname/righteartop [Type Property]
vision/vnanimalbodyposeobservation/jointname/righteye [Type Property]
vision/vnanimalbodyposeobservation/jointname/rightfrontelbow [Type Property]
vision/vnanimalbodyposeobservation/jointname/rightfrontknee [Type Property]
vision/vnanimalbodyposeobservation/jointname/rightfrontpaw [Type Property]
vision/vnanimalbodyposeobservation/jointname/tailbottom [Type Property]
vision/vnanimalbodyposeobservation/jointname/tailmiddle [Type Property]
vision/vnanimalbodyposeobservation/jointname/tailtop [Type Property]
vision/vnanimalbodyposeobservation/jointsgroupname [Structure]
vision/vnanimalbodyposeobservation/jointsgroupname/all [Type Property]
vision/vnanimalbodyposeobservation/jointsgroupname/forelegs [Type Property]
vision/vnanimalbodyposeobservation/jointsgroupname/head [Type Property]
vision/vnanimalbodyposeobservation/jointsgroupname/hindlegs [Type Property]
vision/vnanimalbodyposeobservation/jointsgroupname/init(rawvalue:) [Initializer]
vision/vnanimalbodyposeobservation/jointsgroupname/tail [Type Property]
vision/vnanimalbodyposeobservation/jointsgroupname/trunk [Type Property]
vision/vnanimalbodyposeobservation/recognizedpoint(_:) [Instance Method]
vision/vnanimalbodyposeobservation/recognizedpoints(_:) [Instance Method]

vision/vnanimalidentifier [Structure]
vision/vnanimalidentifier/cat [Type Property]
vision/vnanimalidentifier/dog [Type Property]
vision/vnanimalidentifier/init(rawvalue:) [Initializer]

vision/vnaspectratio [Type Alias]

vision/vnbarcodecompositetype [Enumeration]
vision/vnbarcodecompositetype/gs1typea [Case]
vision/vnbarcodecompositetype/gs1typeb [Case]
vision/vnbarcodecompositetype/gs1typec [Case]
vision/vnbarcodecompositetype/init(rawvalue:) [Initializer]
vision/vnbarcodecompositetype/linked [Case]
vision/vnbarcodecompositetype/none [Case]

vision/vnbarcodeobservation [Class]
vision/vnbarcodeobservation/barcodedescriptor [Instance Property]
vision/vnbarcodeobservation/iscolorinverted [Instance Property]
vision/vnbarcodeobservation/isgs1datacarrier [Instance Property]
vision/vnbarcodeobservation/payloaddata [Instance Property]
vision/vnbarcodeobservation/payloadstringvalue [Instance Property]
vision/vnbarcodeobservation/supplementalcompositetype [Instance Property]
vision/vnbarcodeobservation/supplementalpayloaddata [Instance Property]
vision/vnbarcodeobservation/supplementalpayloadstring [Instance Property]
vision/vnbarcodeobservation/symbology [Instance Property]

vision/vnbarcodesymbology [Structure]
vision/vnbarcodesymbology/aztec-6g0vi [Type Property, deprecated (renamed: aztec)]
vision/vnbarcodesymbology/aztec-s3va [Type Property]
vision/vnbarcodesymbology/codabar [Type Property]
vision/vnbarcodesymbology/code128-1lkm2 [Type Property]
vision/vnbarcodesymbology/code128-7spp7 [Type Property, deprecated (renamed: code128)]
vision/vnbarcodesymbology/code39-2ggrb [Type Property]
vision/vnbarcodesymbology/code39-34358 [Type Property, deprecated (renamed: code39)]
vision/vnbarcodesymbology/code39checksum-2jrn [Type Property, deprecated (renamed: code39Checksum)]
vision/vnbarcodesymbology/code39checksum-3jdl6 [Type Property]
vision/vnbarcodesymbology/code39fullascii-942jj [Type Property]
vision/vnbarcodesymbology/code39fullascii-m5wd [Type Property, deprecated (renamed: code39FullASCII)]
vision/vnbarcodesymbology/code39fullasciichecksum-5xnfs [Type Property, deprecated (renamed: code39FullASCIIChecksum)]
vision/vnbarcodesymbology/code39fullasciichecksum-6700 [Type Property]
vision/vnbarcodesymbology/code93-2geph [Type Property]
vision/vnbarcodesymbology/code93-67nn0 [Type Property, deprecated (renamed: code93)]
vision/vnbarcodesymbology/code93i-84cmv [Type Property, deprecated (renamed: code93i)]
vision/vnbarcodesymbology/code93i-t5q5 [Type Property]
vision/vnbarcodesymbology/datamatrix-2fgc9 [Type Property, deprecated (renamed: dataMatrix)]
vision/vnbarcodesymbology/datamatrix-6tg7m [Type Property]
vision/vnbarcodesymbology/ean13-7gb2d [Type Property]
vision/vnbarcodesymbology/ean13-8ir8e [Type Property, deprecated (renamed: ean13)]
vision/vnbarcodesymbology/ean8-4rzbb [Type Property, deprecated (renamed: ean8)]
vision/vnbarcodesymbology/ean8-9qg0n [Type Property]
vision/vnbarcodesymbology/gs1databar [Type Property]
vision/vnbarcodesymbology/gs1databarexpanded [Type Property]
vision/vnbarcodesymbology/gs1databarlimited [Type Property]
vision/vnbarcodesymbology/i2of5-1r8e7 [Type Property, deprecated (renamed: i2of5)]
vision/vnbarcodesymbology/i2of5-cyk4 [Type Property]
vision/vnbarcodesymbology/i2of5checksum-832s5 [Type Property, deprecated (renamed: i2of5Checksum)]
vision/vnbarcodesymbology/i2of5checksum-999jm [Type Property]
vision/vnbarcodesymbology/init(rawvalue:) [Initializer]
vision/vnbarcodesymbology/itf14-1wp9s [Type Property, deprecated (renamed: itf14)]
vision/vnbarcodesymbology/itf14-9mbkq [Type Property]
vision/vnbarcodesymbology/micropdf417 [Type Property]
vision/vnbarcodesymbology/microqr [Type Property]
vision/vnbarcodesymbology/msiplessey [Type Property]
vision/vnbarcodesymbology/pdf417-56ney [Type Property, deprecated (renamed: pdf417)]
vision/vnbarcodesymbology/pdf417-8n3oh [Type Property]
vision/vnbarcodesymbology/qr-2l1ve [Type Property]
vision/vnbarcodesymbology/qr-2zqax [Type Property, deprecated (renamed: qr)]
vision/vnbarcodesymbology/upce-1jtoc [Type Property]
vision/vnbarcodesymbology/upce-7qps5 [Type Property, deprecated (renamed: upce)]

vision/vncalculateimageaestheticsscoresrequest [Class]
vision/vncalculateimageaestheticsscoresrequest/results [Instance Property]

vision/vncalculateimageaestheticsscoresrequestrevision1 [Global Variable]

vision/vnchirality [Enumeration]
vision/vnchirality/init(rawvalue:) [Initializer]
vision/vnchirality/left [Case]
vision/vnchirality/right [Case]
vision/vnchirality/unknown [Case]

vision/vncircle [Class]
vision/vncircle/center [Instance Property]
vision/vncircle/contains(_:) [Instance Method]
vision/vncircle/contains(_:incircumferentialringofwidth:) [Instance Method]
vision/vncircle/diameter [Instance Property]
vision/vncircle/init(center:diameter:) [Initializer]
vision/vncircle/init(center:radius:) [Initializer]
vision/vncircle/init(coder:) [Initializer]
vision/vncircle/radius [Instance Property]
vision/vncircle/zero [Type Property]

vision/vnclassificationobservation [Class]
vision/vnclassificationobservation/hasminimumprecision(_:forrecall:) [Instance Method]
vision/vnclassificationobservation/hasminimumrecall(_:forprecision:) [Instance Method]
vision/vnclassificationobservation/hasprecisionrecallcurve [Instance Property]
vision/vnclassificationobservation/identifier [Instance Property]

vision/vnclassifyimagerequest [Class]
vision/vnclassifyimagerequest/knownclassifications(forrevision:) [Type Method, deprecated]
vision/vnclassifyimagerequest/results [Instance Property]
vision/vnclassifyimagerequest/supportedidentifiers() [Instance Method]

vision/vnclassifyimagerequestrevision1 [Global Variable]

vision/vnclassifyimagerequestrevision2 [Global Variable]

vision/vncomputestage [Structure]
vision/vncomputestage/init(rawvalue:) [Initializer]
vision/vncomputestage/main [Type Property]
vision/vncomputestage/postprocessing [Type Property]

vision/vnconfidence [Type Alias]

vision/vncontour [Class]
vision/vncontour/aspectratio [Instance Property]
vision/vncontour/childcontour(at:) [Instance Method]
vision/vncontour/childcontourcount [Instance Property]
vision/vncontour/childcontours [Instance Property]
vision/vncontour/indexpath [Instance Property]
vision/vncontour/normalizedpath [Instance Property]
vision/vncontour/normalizedpoints-8n2s5 [Instance Property]
vision/vncontour/pointcount [Instance Property]
vision/vncontour/polygonapproximation(epsilon:) [Instance Method]

vision/vncontoursobservation [Class]
vision/vncontoursobservation/contour(at:)-52odo [Instance Method]
vision/vncontoursobservation/contour(at:)-9on0y [Instance Method]
vision/vncontoursobservation/contourcount [Instance Property]
vision/vncontoursobservation/normalizedpath [Instance Property]
vision/vncontoursobservation/toplevelcontourcount [Instance Property]
vision/vncontoursobservation/toplevelcontours [Instance Property]

vision/vncoremlfeaturevalueobservation [Class]
vision/vncoremlfeaturevalueobservation/featurename [Instance Property]
vision/vncoremlfeaturevalueobservation/featurevalue [Instance Property]

vision/vncoremlmodel [Class]
vision/vncoremlmodel/featureprovider [Instance Property]
vision/vncoremlmodel/init(for:) [Initializer]
vision/vncoremlmodel/init(formlmodel:) [Initializer]
vision/vncoremlmodel/inputimagefeaturename [Instance Property]

vision/vncoremlrequest [Class]
vision/vncoremlrequest/imagecropandscaleoption [Instance Property]
vision/vncoremlrequest/init(model:) [Initializer]
vision/vncoremlrequest/init(model:completionhandler:) [Initializer]
vision/vncoremlrequest/model [Instance Property]

vision/vncoremlrequestrevision1 [Global Variable]

vision/vndegrees [Type Alias]

vision/vndetectanimalbodyposerequest [Class]
vision/vndetectanimalbodyposerequest/results [Instance Property]
vision/vndetectanimalbodyposerequest/supportedjointnames [Instance Property]
vision/vndetectanimalbodyposerequest/supportedjointsgroupnames [Instance Property]

vision/vndetectanimalbodyposerequestrevision1 [Global Variable]

vision/vndetectbarcodesrequest [Class]
vision/vndetectbarcodesrequest/coalescecompositesymbologies [Instance Property]
vision/vndetectbarcodesrequest/results [Instance Property]
vision/vndetectbarcodesrequest/supportedsymbologies [Type Property, deprecated]
vision/vndetectbarcodesrequest/supportedsymbologies() [Instance Method]
vision/vndetectbarcodesrequest/symbologies [Instance Property]

vision/vndetectbarcodesrequestrevision1 [Global Variable, deprecated (renamed: VNDetectBarcodesRequestRevision3)]

vision/vndetectbarcodesrequestrevision2 [Global Variable, deprecated (renamed: VNDetectBarcodesRequestRevision3)]

vision/vndetectbarcodesrequestrevision3 [Global Variable]

vision/vndetectbarcodesrequestrevision4 [Global Variable]

vision/vndetectcontourrequestrevision1 [Global Variable]

vision/vndetectcontoursrequest [Class]
vision/vndetectcontoursrequest/contrastadjustment [Instance Property]
vision/vndetectcontoursrequest/contrastpivot [Instance Property]
vision/vndetectcontoursrequest/detectdarkonlight [Instance Property, deprecated]
vision/vndetectcontoursrequest/detectsdarkonlight [Instance Property]
vision/vndetectcontoursrequest/maximumimagedimension [Instance Property]
vision/vndetectcontoursrequest/results [Instance Property]

vision/vndetectdocumentsegmentationrequest [Class]
vision/vndetectdocumentsegmentationrequest/results [Instance Property]

vision/vndetectdocumentsegmentationrequestrevision1 [Global Variable]

vision/vndetectedobjectobservation [Class]
vision/vndetectedobjectobservation/boundingbox [Instance Property]
vision/vndetectedobjectobservation/globalsegmentationmask [Instance Property]
vision/vndetectedobjectobservation/init(boundingbox:) [Initializer]
vision/vndetectedobjectobservation/init(requestrevision:boundingbox:) [Initializer]

vision/vndetectedpoint [Class]
vision/vndetectedpoint/confidence [Instance Property]

vision/vndetectfacecapturequalityrequest [Class]
vision/vndetectfacecapturequalityrequest/results [Instance Property]

vision/vndetectfacecapturequalityrequestrevision1 [Global Variable]

vision/vndetectfacecapturequalityrequestrevision2 [Global Variable]

vision/vndetectfacecapturequalityrequestrevision3 [Global Variable]

vision/vndetectfacelandmarksrequest [Class]
vision/vndetectfacelandmarksrequest/constellation [Instance Property]
vision/vndetectfacelandmarksrequest/results [Instance Property]
vision/vndetectfacelandmarksrequest/revision(_:supportsconstellation:) [Type Method]

vision/vndetectfacelandmarksrequestrevision1 [Global Variable, deprecated (renamed: VNDetectFaceLandmarksRequestRevision2)]

vision/vndetectfacelandmarksrequestrevision2 [Global Variable]

vision/vndetectfacelandmarksrequestrevision3 [Global Variable]

vision/vndetectfacerectanglesrequest [Class]
vision/vndetectfacerectanglesrequest/results [Instance Property]

vision/vndetectfacerectanglesrequestrevision1 [Global Variable, deprecated (renamed: VNDetectFaceRectanglesRequestRevision2)]

vision/vndetectfacerectanglesrequestrevision2 [Global Variable]

vision/vndetectfacerectanglesrequestrevision3 [Global Variable]

vision/vndetecthorizonrequest [Class]
vision/vndetecthorizonrequest/results [Instance Property]

vision/vndetecthorizonrequestrevision1 [Global Variable]

vision/vndetecthumanbodypose3drequest [Class]
vision/vndetecthumanbodypose3drequest/init() [Initializer]
vision/vndetecthumanbodypose3drequest/init(completionhandler:) [Initializer]
vision/vndetecthumanbodypose3drequest/results [Instance Property]
vision/vndetecthumanbodypose3drequest/supportedjointnames [Instance Property]
vision/vndetecthumanbodypose3drequest/supportedjointsgroupnames [Instance Property]

vision/vndetecthumanbodypose3drequestrevision1 [Global Variable]

vision/vndetecthumanbodyposerequest [Class]
vision/vndetecthumanbodyposerequest/results [Instance Property]
vision/vndetecthumanbodyposerequest/supportedjointnames [Instance Property]
vision/vndetecthumanbodyposerequest/supportedjointnames(forrevision:) [Type Method, deprecated]
vision/vndetecthumanbodyposerequest/supportedjointsgroupnames [Instance Property]
vision/vndetecthumanbodyposerequest/supportedjointsgroupnames(forrevision:) [Type Method, deprecated]

vision/vndetecthumanbodyposerequestrevision1 [Global Variable]

vision/vndetecthumanhandposerequest [Class]
vision/vndetecthumanhandposerequest/maximumhandcount [Instance Property]
vision/vndetecthumanhandposerequest/results [Instance Property]
vision/vndetecthumanhandposerequest/supportedjointnames [Instance Property]
vision/vndetecthumanhandposerequest/supportedjointnames(forrevision:) [Type Method, deprecated]
vision/vndetecthumanhandposerequest/supportedjointsgroupnames [Instance Property]
vision/vndetecthumanhandposerequest/supportedjointsgroupnames(forrevision:) [Type Method, deprecated]

vision/vndetecthumanhandposerequestrevision1 [Global Variable]

vision/vndetecthumanrectanglesrequest [Class]
vision/vndetecthumanrectanglesrequest/results [Instance Property]
vision/vndetecthumanrectanglesrequest/upperbodyonly [Instance Property]

vision/vndetecthumanrectanglesrequestrevision1 [Global Variable]

vision/vndetecthumanrectanglesrequestrevision2 [Global Variable]

vision/vndetectrectanglesrequest [Class]
vision/vndetectrectanglesrequest/maximumaspectratio [Instance Property]
vision/vndetectrectanglesrequest/maximumobservations [Instance Property]
vision/vndetectrectanglesrequest/minimumaspectratio [Instance Property]
vision/vndetectrectanglesrequest/minimumconfidence [Instance Property]
vision/vndetectrectanglesrequest/minimumsize [Instance Property]
vision/vndetectrectanglesrequest/quadraturetolerance [Instance Property]
vision/vndetectrectanglesrequest/results [Instance Property]

vision/vndetectrectanglesrequestrevision1 [Global Variable]

vision/vndetecttextrectanglesrequest [Class]
vision/vndetecttextrectanglesrequest/reportcharacterboxes [Instance Property]
vision/vndetecttextrectanglesrequest/results [Instance Property]

vision/vndetecttextrectanglesrequestrevision1 [Global Variable]

vision/vndetecttrajectoriesrequest [Class]
vision/vndetecttrajectoriesrequest/init(frameanalysisspacing:trajectorylength:completionhandler:) [Initializer]
vision/vndetecttrajectoriesrequest/maximumobjectsize [Instance Property, deprecated]
vision/vndetecttrajectoriesrequest/minimumobjectsize [Instance Property, deprecated]
vision/vndetecttrajectoriesrequest/objectmaximumnormalizedradius [Instance Property]
vision/vndetecttrajectoriesrequest/objectminimumnormalizedradius [Instance Property]
vision/vndetecttrajectoriesrequest/results [Instance Property]
vision/vndetecttrajectoriesrequest/targetframetime [Instance Property]
vision/vndetecttrajectoriesrequest/trajectorylength [Instance Property]

vision/vndetecttrajectoriesrequestrevision1 [Global Variable]

vision/vnelementtype [Enumeration]
vision/vnelementtype/double [Case]
vision/vnelementtype/float [Case]
vision/vnelementtype/init(rawvalue:) [Initializer]
vision/vnelementtype/unknown [Case]

vision/vnelementtypesize(_:) [Function]

vision/vnerrorcode [Enumeration]
vision/vnerrorcode/dataunavailable [Case]
vision/vnerrorcode/init(rawvalue:) [Initializer]
vision/vnerrorcode/internalerror [Case]
vision/vnerrorcode/invalidargument [Case]
vision/vnerrorcode/invalidformat [Case]
vision/vnerrorcode/invalidimage [Case]
vision/vnerrorcode/invalidmodel [Case]
vision/vnerrorcode/invalidoperation [Case]
vision/vnerrorcode/invalidoption [Case]
vision/vnerrorcode/ioerror [Case]
vision/vnerrorcode/missingoption [Case]
vision/vnerrorcode/notimplemented [Case]
vision/vnerrorcode/ok [Case]
vision/vnerrorcode/operationfailed [Case]
vision/vnerrorcode/outofboundserror [Case]
vision/vnerrorcode/outofmemory [Case]
vision/vnerrorcode/requestcancelled [Case]
vision/vnerrorcode/resourcecorrupted [Case]
vision/vnerrorcode/resourceunavailable [Case]
vision/vnerrorcode/timeout [Case]
vision/vnerrorcode/timestampnotfound [Case]
vision/vnerrorcode/turicoreerrorcode [Case]
vision/vnerrorcode/unknownerror [Case]
vision/vnerrorcode/unsupportedcomputedevice [Case]
vision/vnerrorcode/unsupportedcomputestage [Case]
vision/vnerrorcode/unsupportedrequest [Case]
vision/vnerrorcode/unsupportedrevision [Case]

vision/vnerrordomain [Global Variable]

vision/vnfacelandmarkregion [Class]
vision/vnfacelandmarkregion/init(coder:) [Initializer]
vision/vnfacelandmarkregion/pointcount [Instance Property]

vision/vnfacelandmarkregion2d [Class]
vision/vnfacelandmarkregion2d/normalizedpoints-7s7im [Instance Property]
vision/vnfacelandmarkregion2d/pointsclassification [Instance Property]
vision/vnfacelandmarkregion2d/pointsinimage(imagesize:) [Instance Method]
vision/vnfacelandmarkregion2d/precisionestimatesperpoint-5jl22 [Instance Property]

vision/vnfacelandmarks [Class]
vision/vnfacelandmarks/confidence [Instance Property]
vision/vnfacelandmarks/init(coder:) [Initializer]

vision/vnfacelandmarks2d [Class]
vision/vnfacelandmarks2d/allpoints [Instance Property]
vision/vnfacelandmarks2d/facecontour [Instance Property]
vision/vnfacelandmarks2d/innerlips [Instance Property]
vision/vnfacelandmarks2d/lefteye [Instance Property]
vision/vnfacelandmarks2d/lefteyebrow [Instance Property]
vision/vnfacelandmarks2d/leftpupil [Instance Property]
vision/vnfacelandmarks2d/medianline [Instance Property]
vision/vnfacelandmarks2d/nose [Instance Property]
vision/vnfacelandmarks2d/nosecrest [Instance Property]
vision/vnfacelandmarks2d/outerlips [Instance Property]
vision/vnfacelandmarks2d/righteye [Instance Property]
vision/vnfacelandmarks2d/righteyebrow [Instance Property]
vision/vnfacelandmarks2d/rightpupil [Instance Property]

vision/vnfaceobservation [Class]
vision/vnfaceobservation/facecapturequality-bjg5 [Instance Property]
vision/vnfaceobservation/init(requestrevision:boundingbox:roll:yaw:) [Initializer, deprecated]
vision/vnfaceobservation/init(requestrevision:boundingbox:roll:yaw:pitch:) [Initializer]
vision/vnfaceobservation/landmarks [Instance Property]
vision/vnfaceobservation/pitch [Instance Property]
vision/vnfaceobservation/roll [Instance Property]
vision/vnfaceobservation/yaw [Instance Property]

vision/vnfaceobservationaccepting [Protocol]
vision/vnfaceobservationaccepting/inputfaceobservations [Instance Property]

vision/vnfeatureprintobservation [Class]
vision/vnfeatureprintobservation/computedistance(_:to:) [Instance Method]
vision/vnfeatureprintobservation/data [Instance Property]
vision/vnfeatureprintobservation/elementcount [Instance Property]
vision/vnfeatureprintobservation/elementtype [Instance Property]

vision/vngenerateattentionbasedsaliencyimagerequest [Class]
vision/vngenerateattentionbasedsaliencyimagerequest/results [Instance Property]

vision/vngenerateattentionbasedsaliencyimagerequestrevision1 [Global Variable]

vision/vngenerateattentionbasedsaliencyimagerequestrevision2 [Global Variable]

vision/vngenerateforegroundinstancemaskrequest [Class]
vision/vngenerateforegroundinstancemaskrequest/results [Instance Property]

vision/vngenerateforegroundinstancemaskrequestrevision1 [Global Variable]

vision/vngenerateimagefeatureprintrequest [Class]
vision/vngenerateimagefeatureprintrequest/imagecropandscaleoption [Instance Property]
vision/vngenerateimagefeatureprintrequest/results [Instance Property]

vision/vngenerateimagefeatureprintrequestrevision1 [Global Variable]

vision/vngenerateimagefeatureprintrequestrevision2 [Global Variable]

vision/vngenerateobjectnessbasedsaliencyimagerequest [Class]
vision/vngenerateobjectnessbasedsaliencyimagerequest/results [Instance Property]

vision/vngenerateobjectnessbasedsaliencyimagerequestrevision1 [Global Variable]

vision/vngenerateobjectnessbasedsaliencyimagerequestrevision2 [Global Variable]

vision/vngenerateopticalflowrequest [Class]
vision/vngenerateopticalflowrequest/computationaccuracy-swift.enum [Enumeration]
vision/vngenerateopticalflowrequest/computationaccuracy-swift.enum/high [Case]
vision/vngenerateopticalflowrequest/computationaccuracy-swift.enum/init(rawvalue:) [Initializer]
vision/vngenerateopticalflowrequest/computationaccuracy-swift.enum/low [Case]
vision/vngenerateopticalflowrequest/computationaccuracy-swift.enum/medium [Case]
vision/vngenerateopticalflowrequest/computationaccuracy-swift.enum/veryhigh [Case]
vision/vngenerateopticalflowrequest/computationaccuracy-swift.property [Instance Property]
vision/vngenerateopticalflowrequest/keepnetworkoutput [Instance Property]
vision/vngenerateopticalflowrequest/outputpixelformat [Instance Property]
vision/vngenerateopticalflowrequest/results [Instance Property]

vision/vngenerateopticalflowrequestrevision1 [Global Variable]

vision/vngenerateopticalflowrequestrevision2 [Global Variable]

vision/vngeneratepersoninstancemaskrequest [Class]
vision/vngeneratepersoninstancemaskrequest/results [Instance Property]

vision/vngeneratepersoninstancemaskrequestrevision1 [Global Variable]

vision/vngeneratepersonsegmentationrequest [Class]
vision/vngeneratepersonsegmentationrequest/init() [Initializer]
vision/vngeneratepersonsegmentationrequest/init(completionhandler:) [Initializer]
vision/vngeneratepersonsegmentationrequest/outputpixelformat [Instance Property]
vision/vngeneratepersonsegmentationrequest/qualitylevel-swift.enum [Enumeration]
vision/vngeneratepersonsegmentationrequest/qualitylevel-swift.enum/accurate [Case]
vision/vngeneratepersonsegmentationrequest/qualitylevel-swift.enum/balanced [Case]
vision/vngeneratepersonsegmentationrequest/qualitylevel-swift.enum/fast [Case]
vision/vngeneratepersonsegmentationrequest/qualitylevel-swift.enum/init(rawvalue:) [Initializer]
vision/vngeneratepersonsegmentationrequest/qualitylevel-swift.property [Instance Property]
vision/vngeneratepersonsegmentationrequest/results [Instance Property]
vision/vngeneratepersonsegmentationrequest/supportedoutputpixelformats() [Instance Method]

vision/vngeneratepersonsegmentationrequestrevision1 [Global Variable]

vision/vngeometryutils [Class]
vision/vngeometryutils/boundingcircle(for:)-423ll [Type Method]
vision/vngeometryutils/boundingcircle(for:)-9dggv [Type Method]
vision/vngeometryutils/boundingcircle(forsimdpoints:pointcount:) [Type Method]
vision/vngeometryutils/calculatearea(_:for:orientedarea:) [Type Method]
vision/vngeometryutils/calculateperimeter(_:for:) [Type Method]

vision/vnhomographicimageregistrationrequest [Class]
vision/vnhomographicimageregistrationrequest/results [Instance Property]

vision/vnhomographicimageregistrationrequestrevision1 [Global Variable]

vision/vnhorizonobservation [Class]
vision/vnhorizonobservation/angle [Instance Property]
vision/vnhorizonobservation/transform [Instance Property]
vision/vnhorizonobservation/transform(forimagewidth:height:) [Instance Method]

vision/vnhumanbodypose3dobservation [Class]
vision/vnhumanbodypose3dobservation/availablejointnames [Instance Property]
vision/vnhumanbodypose3dobservation/availablejointsgroupnames [Instance Property]
vision/vnhumanbodypose3dobservation/bodyheight [Instance Property]
vision/vnhumanbodypose3dobservation/cameraoriginmatrix [Instance Property]
vision/vnhumanbodypose3dobservation/camerarelativeposition(_:) [Instance Method]
vision/vnhumanbodypose3dobservation/heightestimation-swift.enum [Enumeration]
vision/vnhumanbodypose3dobservation/heightestimation-swift.enum/init(rawvalue:) [Initializer]
vision/vnhumanbodypose3dobservation/heightestimation-swift.enum/measured [Case]
vision/vnhumanbodypose3dobservation/heightestimation-swift.enum/reference [Case]
vision/vnhumanbodypose3dobservation/heightestimation-swift.property [Instance Property]
vision/vnhumanbodypose3dobservation/jointname [Structure]
vision/vnhumanbodypose3dobservation/jointname/centerhead [Type Property]
vision/vnhumanbodypose3dobservation/jointname/centershoulder [Type Property]
vision/vnhumanbodypose3dobservation/jointname/init(rawvalue:) [Initializer]
vision/vnhumanbodypose3dobservation/jointname/leftankle [Type Property]
vision/vnhumanbodypose3dobservation/jointname/leftelbow [Type Property]
vision/vnhumanbodypose3dobservation/jointname/lefthip [Type Property]
vision/vnhumanbodypose3dobservation/jointname/leftknee [Type Property]
vision/vnhumanbodypose3dobservation/jointname/leftshoulder [Type Property]
vision/vnhumanbodypose3dobservation/jointname/leftwrist [Type Property]
vision/vnhumanbodypose3dobservation/jointname/rightankle [Type Property]
vision/vnhumanbodypose3dobservation/jointname/rightelbow [Type Property]
vision/vnhumanbodypose3dobservation/jointname/righthip [Type Property]
vision/vnhumanbodypose3dobservation/jointname/rightknee [Type Property]
vision/vnhumanbodypose3dobservation/jointname/rightshoulder [Type Property]
vision/vnhumanbodypose3dobservation/jointname/rightwrist [Type Property]
vision/vnhumanbodypose3dobservation/jointname/root [Type Property]
vision/vnhumanbodypose3dobservation/jointname/spine [Type Property]
vision/vnhumanbodypose3dobservation/jointname/tophead [Type Property]
vision/vnhumanbodypose3dobservation/jointsgroupname [Structure]
vision/vnhumanbodypose3dobservation/jointsgroupname/all [Type Property]
vision/vnhumanbodypose3dobservation/jointsgroupname/head [Type Property]
vision/vnhumanbodypose3dobservation/jointsgroupname/init(rawvalue:) [Initializer]
vision/vnhumanbodypose3dobservation/jointsgroupname/leftarm [Type Property]
vision/vnhumanbodypose3dobservation/jointsgroupname/leftleg [Type Property]
vision/vnhumanbodypose3dobservation/jointsgroupname/rightarm [Type Property]
vision/vnhumanbodypose3dobservation/jointsgroupname/rightleg [Type Property]
vision/vnhumanbodypose3dobservation/jointsgroupname/torso [Type Property]
vision/vnhumanbodypose3dobservation/parentjointname(_:) [Instance Method]
vision/vnhumanbodypose3dobservation/pointinimage(_:) [Instance Method]
vision/vnhumanbodypose3dobservation/recognizedpoint(_:) [Instance Method]
vision/vnhumanbodypose3dobservation/recognizedpoints(_:) [Instance Method]

vision/vnhumanbodyposeobservation [Class]
vision/vnhumanbodyposeobservation/availablejointnames [Instance Property]
vision/vnhumanbodyposeobservation/availablejointsgroupnames [Instance Property]
vision/vnhumanbodyposeobservation/jointname [Structure]
vision/vnhumanbodyposeobservation/jointname/init(rawvalue:) [Initializer]
vision/vnhumanbodyposeobservation/jointname/leftankle [Type Property]
vision/vnhumanbodyposeobservation/jointname/leftear [Type Property]
vision/vnhumanbodyposeobservation/jointname/leftelbow [Type Property]
vision/vnhumanbodyposeobservation/jointname/lefteye [Type Property]
vision/vnhumanbodyposeobservation/jointname/lefthip [Type Property]
vision/vnhumanbodyposeobservation/jointname/leftknee [Type Property]
vision/vnhumanbodyposeobservation/jointname/leftshoulder [Type Property]
vision/vnhumanbodyposeobservation/jointname/leftwrist [Type Property]
vision/vnhumanbodyposeobservation/jointname/neck [Type Property]
vision/vnhumanbodyposeobservation/jointname/nose [Type Property]
vision/vnhumanbodyposeobservation/jointname/rightankle [Type Property]
vision/vnhumanbodyposeobservation/jointname/rightear [Type Property]
vision/vnhumanbodyposeobservation/jointname/rightelbow [Type Property]
vision/vnhumanbodyposeobservation/jointname/righteye [Type Property]
vision/vnhumanbodyposeobservation/jointname/righthip [Type Property]
vision/vnhumanbodyposeobservation/jointname/rightknee [Type Property]
vision/vnhumanbodyposeobservation/jointname/rightshoulder [Type Property]
vision/vnhumanbodyposeobservation/jointname/rightwrist [Type Property]
vision/vnhumanbodyposeobservation/jointname/root [Type Property]
vision/vnhumanbodyposeobservation/jointsgroupname [Structure]
vision/vnhumanbodyposeobservation/jointsgroupname/all [Type Property]
vision/vnhumanbodyposeobservation/jointsgroupname/face [Type Property]
vision/vnhumanbodyposeobservation/jointsgroupname/init(rawvalue:) [Initializer]
vision/vnhumanbodyposeobservation/jointsgroupname/leftarm [Type Property]
vision/vnhumanbodyposeobservation/jointsgroupname/leftleg [Type Property]
vision/vnhumanbodyposeobservation/jointsgroupname/rightarm [Type Property]
vision/vnhumanbodyposeobservation/jointsgroupname/rightleg [Type Property]
vision/vnhumanbodyposeobservation/jointsgroupname/torso [Type Property]
vision/vnhumanbodyposeobservation/recognizedpoint(_:) [Instance Method]
vision/vnhumanbodyposeobservation/recognizedpoints(_:) [Instance Method]

vision/vnhumanbodyrecognizedpoint3d [Class]
vision/vnhumanbodyrecognizedpoint3d/localposition [Instance Property]
vision/vnhumanbodyrecognizedpoint3d/parentjoint [Instance Property]

vision/vnhumanhandposeobservation [Class]
vision/vnhumanhandposeobservation/availablejointnames [Instance Property]
vision/vnhumanhandposeobservation/availablejointsgroupnames [Instance Property]
vision/vnhumanhandposeobservation/chirality [Instance Property]
vision/vnhumanhandposeobservation/jointname [Structure]
vision/vnhumanhandposeobservation/jointname/indexdip [Type Property]
vision/vnhumanhandposeobservation/jointname/indexmcp [Type Property]
vision/vnhumanhandposeobservation/jointname/indexpip [Type Property]
vision/vnhumanhandposeobservation/jointname/indextip [Type Property]
vision/vnhumanhandposeobservation/jointname/init(rawvalue:) [Initializer]
vision/vnhumanhandposeobservation/jointname/littledip [Type Property]
vision/vnhumanhandposeobservation/jointname/littlemcp [Type Property]
vision/vnhumanhandposeobservation/jointname/littlepip [Type Property]
vision/vnhumanhandposeobservation/jointname/littletip [Type Property]
vision/vnhumanhandposeobservation/jointname/middledip [Type Property]
vision/vnhumanhandposeobservation/jointname/middlemcp [Type Property]
vision/vnhumanhandposeobservation/jointname/middlepip [Type Property]
vision/vnhumanhandposeobservation/jointname/middletip [Type Property]
vision/vnhumanhandposeobservation/jointname/ringdip [Type Property]
vision/vnhumanhandposeobservation/jointname/ringmcp [Type Property]
vision/vnhumanhandposeobservation/jointname/ringpip [Type Property]
vision/vnhumanhandposeobservation/jointname/ringtip [Type Property]
vision/vnhumanhandposeobservation/jointname/thumbcmc [Type Property]
vision/vnhumanhandposeobservation/jointname/thumbip [Type Property]
vision/vnhumanhandposeobservation/jointname/thumbmp [Type Property]
vision/vnhumanhandposeobservation/jointname/thumbtip [Type Property]
vision/vnhumanhandposeobservation/jointname/wrist [Type Property]
vision/vnhumanhandposeobservation/jointsgroupname [Structure]
vision/vnhumanhandposeobservation/jointsgroupname/all [Type Property]
vision/vnhumanhandposeobservation/jointsgroupname/indexfinger [Type Property]
vision/vnhumanhandposeobservation/jointsgroupname/init(rawvalue:) [Initializer]
vision/vnhumanhandposeobservation/jointsgroupname/littlefinger [Type Property]
vision/vnhumanhandposeobservation/jointsgroupname/middlefinger [Type Property]
vision/vnhumanhandposeobservation/jointsgroupname/ringfinger [Type Property]
vision/vnhumanhandposeobservation/jointsgroupname/thumb [Type Property]
vision/vnhumanhandposeobservation/recognizedpoint(_:) [Instance Method]
vision/vnhumanhandposeobservation/recognizedpoints(_:) [Instance Method]

vision/vnhumanobservation [Class]
vision/vnhumanobservation/upperbodyonly [Instance Property]

vision/vnimageaestheticsscoresobservation [Class]
vision/vnimageaestheticsscoresobservation/isutility [Instance Property]
vision/vnimageaestheticsscoresobservation/overallscore [Instance Property]

vision/vnimagealignmentobservation [Class]

vision/vnimagebasedrequest [Class]
vision/vnimagebasedrequest/regionofinterest [Instance Property]

vision/vnimagecropandscaleoption [Enumeration]
vision/vnimagecropandscaleoption/centercrop [Case]
vision/vnimagecropandscaleoption/init(rawvalue:) [Initializer]
vision/vnimagecropandscaleoption/scalefill [Case]
vision/vnimagecropandscaleoption/scalefillrotate90ccw [Case]
vision/vnimagecropandscaleoption/scalefit [Case]
vision/vnimagecropandscaleoption/scalefitrotate90ccw [Case]

vision/vnimagehomographicalignmentobservation [Class]
vision/vnimagehomographicalignmentobservation/warptransform [Instance Property]

vision/vnimageoption [Structure]
vision/vnimageoption/cameraintrinsics [Type Property]
vision/vnimageoption/cicontext [Type Property]
vision/vnimageoption/init(rawvalue:) [Initializer]
vision/vnimageoption/properties [Type Property]

vision/vnimagepointforfacelandmarkpoint(_:_:_:_:) [Function]

vision/vnimagepointfornormalizedpoint(_:_:_:) [Function]

vision/vnimagepointfornormalizedpointusingregionofinterest(_:_:_:_:) [Function]

vision/vnimagerectfornormalizedrect(_:_:_:) [Function]

vision/vnimagerectfornormalizedrectusingregionofinterest(_:_:_:_:) [Function]

vision/vnimageregistrationrequest [Class]

vision/vnimagerequesthandler [Class]
vision/vnimagerequesthandler/init(cgimage:options:)-4qda6 [Initializer]
vision/vnimagerequesthandler/init(cgimage:options:)-5tp19 [Initializer]
vision/vnimagerequesthandler/init(cgimage:orientation:options:)-63ojm [Initializer]
vision/vnimagerequesthandler/init(cgimage:orientation:options:)-8imhf [Initializer]
vision/vnimagerequesthandler/init(ciimage:options:)-4wf33 [Initializer]
vision/vnimagerequesthandler/init(ciimage:options:)-55zel [Initializer]
vision/vnimagerequesthandler/init(ciimage:orientation:options:)-3svy6 [Initializer]
vision/vnimagerequesthandler/init(ciimage:orientation:options:)-8p8h1 [Initializer]
vision/vnimagerequesthandler/init(cmsamplebuffer:depthdata:orientation:options:)-8bjyh [Initializer]
vision/vnimagerequesthandler/init(cmsamplebuffer:depthdata:orientation:options:)-yi6q [Initializer]
vision/vnimagerequesthandler/init(cmsamplebuffer:options:)-2yodn [Initializer]
vision/vnimagerequesthandler/init(cmsamplebuffer:options:)-4mpwd [Initializer]
vision/vnimagerequesthandler/init(cmsamplebuffer:orientation:options:)-335k4 [Initializer]
vision/vnimagerequesthandler/init(cmsamplebuffer:orientation:options:)-6qeht [Initializer]
vision/vnimagerequesthandler/init(cvpixelbuffer:depthdata:orientation:options:)-3mj2d [Initializer]
vision/vnimagerequesthandler/init(cvpixelbuffer:depthdata:orientation:options:)-3u960 [Initializer]
vision/vnimagerequesthandler/init(cvpixelbuffer:options:)-3pee9 [Initializer]
vision/vnimagerequesthandler/init(cvpixelbuffer:options:)-bkd7 [Initializer]
vision/vnimagerequesthandler/init(cvpixelbuffer:orientation:options:)-160f [Initializer]
vision/vnimagerequesthandler/init(cvpixelbuffer:orientation:options:)-9fxug [Initializer]
vision/vnimagerequesthandler/init(data:options:) [Initializer]
vision/vnimagerequesthandler/init(data:orientation:options:) [Initializer]
vision/vnimagerequesthandler/init(url:options:)-19t0u [Initializer]
vision/vnimagerequesthandler/init(url:options:)-4k623 [Initializer]
vision/vnimagerequesthandler/init(url:orientation:options:)-70nta [Initializer]
vision/vnimagerequesthandler/init(url:orientation:options:)-ou7m [Initializer]
vision/vnimagerequesthandler/perform(_:) [Instance Method]

vision/vnimagetranslationalignmentobservation [Class]
vision/vnimagetranslationalignmentobservation/alignmenttransform [Instance Property]

vision/vninstancemaskobservation [Class]
vision/vninstancemaskobservation/allinstances [Instance Property]
vision/vninstancemaskobservation/generatemask(forinstances:) [Instance Method]
vision/vninstancemaskobservation/generatemaskedimage(ofinstances:from:croppedtoinstancesextent:) [Instance Method]
vision/vninstancemaskobservation/generatescaledmaskforimage(forinstances:from:) [Instance Method]
vision/vninstancemaskobservation/instancemask [Instance Property]

vision/vnnormalizedfaceboundingboxpointforlandmarkpoint(_:_:_:_:) [Function]

vision/vnnormalizedidentityrect [Global Variable]

vision/vnnormalizedpointforimagepoint(_:_:_:) [Function]

vision/vnnormalizedpointforimagepointusingregionofinterest(_:_:_:_:) [Function]

vision/vnnormalizedrectforimagerect(_:_:_:) [Function]

vision/vnnormalizedrectforimagerectusingregionofinterest(_:_:_:_:) [Function]

vision/vnnormalizedrectisidentityrect(_:) [Function]

vision/vnobservation [Class]
vision/vnobservation/confidence [Instance Property]
vision/vnobservation/init(coder:) [Initializer]
vision/vnobservation/timerange [Instance Property]
vision/vnobservation/uuid [Instance Property]

vision/vnpixelbufferobservation [Class]
vision/vnpixelbufferobservation/featurename [Instance Property]
vision/vnpixelbufferobservation/pixelbuffer [Instance Property]

vision/vnpoint [Class]
vision/vnpoint/apply(_:to:) [Type Method]
vision/vnpoint/distance(_:) [Instance Method]
vision/vnpoint/distance(_:_:) [Type Method, deprecated]
vision/vnpoint/init(coder:) [Initializer]
vision/vnpoint/init(location:) [Initializer]
vision/vnpoint/init(x:y:) [Initializer]
vision/vnpoint/location [Instance Property]
vision/vnpoint/x [Instance Property]
vision/vnpoint/y [Instance Property]
vision/vnpoint/zero [Type Property]

vision/vnpoint3d [Class]
vision/vnpoint3d/init(coder:) [Initializer]
vision/vnpoint3d/init(position:) [Initializer]
vision/vnpoint3d/position [Instance Property]

vision/vnpointsclassification [Enumeration]
vision/vnpointsclassification/closedpath [Case]
vision/vnpointsclassification/disconnected [Case]
vision/vnpointsclassification/init(rawvalue:) [Initializer]
vision/vnpointsclassification/openpath [Case]

vision/vnrecognizeanimalsrequest [Class]
vision/vnrecognizeanimalsrequest/knownanimalidentifiers(forrevision:) [Type Method, deprecated]
vision/vnrecognizeanimalsrequest/results [Instance Property]
vision/vnrecognizeanimalsrequest/supportedidentifiers() [Instance Method]

vision/vnrecognizeanimalsrequestrevision1 [Global Variable]

vision/vnrecognizeanimalsrequestrevision2 [Global Variable]

vision/vnrecognizedobjectobservation [Class]
vision/vnrecognizedobjectobservation/labels [Instance Property]

vision/vnrecognizedpoint [Class]
vision/vnrecognizedpoint/identifier [Instance Property]

vision/vnrecognizedpoint3d [Class]
vision/vnrecognizedpoint3d/identifier [Instance Property]

vision/vnrecognizedpointgroupkey [Structure]
vision/vnrecognizedpointgroupkey/all [Type Property]
vision/vnrecognizedpointgroupkey/bodylandmarkregionkeyface [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointsGroupName.face)]
vision/vnrecognizedpointgroupkey/bodylandmarkregionkeyleftarm [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointsGroupName.leftArm)]
vision/vnrecognizedpointgroupkey/bodylandmarkregionkeyleftleg [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointsGroupName.leftLeg)]
vision/vnrecognizedpointgroupkey/bodylandmarkregionkeyrightarm [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointsGroupName.rightArm)]
vision/vnrecognizedpointgroupkey/bodylandmarkregionkeyrightleg [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointsGroupName.rightLeg)]
vision/vnrecognizedpointgroupkey/bodylandmarkregionkeytorso [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointsGroupName.torso)]
vision/vnrecognizedpointgroupkey/init(rawvalue:) [Initializer]
vision/vnrecognizedpointgroupkey/point3dgroupkeyall [Type Property]

vision/vnrecognizedpointkey [Structure]
vision/vnrecognizedpointkey/bodylandmarkkeyleftankle [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftAnkle)]
vision/vnrecognizedpointkey/bodylandmarkkeyleftear [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftEar)]
vision/vnrecognizedpointkey/bodylandmarkkeyleftelbow [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftElbow)]
vision/vnrecognizedpointkey/bodylandmarkkeylefteye [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftEye)]
vision/vnrecognizedpointkey/bodylandmarkkeylefthip [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftHip)]
vision/vnrecognizedpointkey/bodylandmarkkeyleftknee [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftKnee)]
vision/vnrecognizedpointkey/bodylandmarkkeyleftshoulder [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftShoulder)]
vision/vnrecognizedpointkey/bodylandmarkkeyleftwrist [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.leftWrist)]
vision/vnrecognizedpointkey/bodylandmarkkeyneck [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.neck)]
vision/vnrecognizedpointkey/bodylandmarkkeynose [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.nose)]
vision/vnrecognizedpointkey/bodylandmarkkeyrightankle [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightAnkle)]
vision/vnrecognizedpointkey/bodylandmarkkeyrightear [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightEar)]
vision/vnrecognizedpointkey/bodylandmarkkeyrightelbow [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightElbow)]
vision/vnrecognizedpointkey/bodylandmarkkeyrighteye [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightEye)]
vision/vnrecognizedpointkey/bodylandmarkkeyrighthip [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightHip)]
vision/vnrecognizedpointkey/bodylandmarkkeyrightknee [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightKnee)]
vision/vnrecognizedpointkey/bodylandmarkkeyrightshoulder [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightShoulder)]
vision/vnrecognizedpointkey/bodylandmarkkeyrightwrist [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.rightWrist)]
vision/vnrecognizedpointkey/bodylandmarkkeyroot [Type Property, deprecated (renamed: VNHumanBodyPoseObservation.JointName.root)]
vision/vnrecognizedpointkey/init(rawvalue:) [Initializer]

vision/vnrecognizedpoints3dobservation [Class]
vision/vnrecognizedpoints3dobservation/availablegroupkeys [Instance Property]
vision/vnrecognizedpoints3dobservation/availablekeys [Instance Property]
vision/vnrecognizedpoints3dobservation/recognizedpoint(forkey:) [Instance Method]
vision/vnrecognizedpoints3dobservation/recognizedpoints(forgroupkey:) [Instance Method]

vision/vnrecognizedpointsobservation [Class]
vision/vnrecognizedpointsobservation/availablegroupkeys [Instance Property]
vision/vnrecognizedpointsobservation/availablekeys [Instance Property]
vision/vnrecognizedpointsobservation/keypointsmultiarray() [Instance Method]
vision/vnrecognizedpointsobservation/recognizedpoint(forkey:) [Instance Method]
vision/vnrecognizedpointsobservation/recognizedpoints(forgroupkey:) [Instance Method]

vision/vnrecognizedtext [Class]
vision/vnrecognizedtext/boundingbox(for:) [Instance Method]
vision/vnrecognizedtext/confidence [Instance Property]
vision/vnrecognizedtext/init(coder:) [Initializer]
vision/vnrecognizedtext/string [Instance Property]

vision/vnrecognizedtextobservation [Class]
vision/vnrecognizedtextobservation/topcandidates(_:) [Instance Method]

vision/vnrecognizetextrequest [Class]
vision/vnrecognizetextrequest/automaticallydetectslanguage [Instance Property]
vision/vnrecognizetextrequest/customwords [Instance Property]
vision/vnrecognizetextrequest/minimumtextheight [Instance Property]
vision/vnrecognizetextrequest/recognitionlanguages [Instance Property]
vision/vnrecognizetextrequest/recognitionlevel [Instance Property]
vision/vnrecognizetextrequest/results [Instance Property]
vision/vnrecognizetextrequest/supportedrecognitionlanguages() [Instance Method]
vision/vnrecognizetextrequest/supportedrecognitionlanguages(for:revision:) [Type Method, deprecated]
vision/vnrecognizetextrequest/useslanguagecorrection [Instance Property]

vision/vnrecognizetextrequestrevision1 [Global Variable, deprecated (renamed: VNRecognizeTextRequestRevision3)]

vision/vnrecognizetextrequestrevision2 [Global Variable, deprecated (renamed: VNRecognizeTextRequestRevision3)]

vision/vnrecognizetextrequestrevision3 [Global Variable]

vision/vnrectangleobservation [Class]
vision/vnrectangleobservation/bottomleft [Instance Property]
vision/vnrectangleobservation/bottomright [Instance Property]
vision/vnrectangleobservation/init(requestrevision:topleft:bottomleft:bottomright:topright:) [Initializer, deprecated]
vision/vnrectangleobservation/init(requestrevision:topleft:topright:bottomright:bottomleft:) [Initializer]
vision/vnrectangleobservation/topleft [Instance Property]
vision/vnrectangleobservation/topright [Instance Property]

vision/vnrequest [Class]
vision/vnrequest/cancel() [Instance Method]
vision/vnrequest/completionhandler [Instance Property]
vision/vnrequest/computedevice(for:) [Instance Method]
vision/vnrequest/currentrevision [Type Property]
vision/vnrequest/defaultrevision [Type Property]
vision/vnrequest/init() [Initializer]
vision/vnrequest/init(completionhandler:) [Initializer]
vision/vnrequest/preferbackgroundprocessing [Instance Property]
vision/vnrequest/results [Instance Property]
vision/vnrequest/revision [Instance Property]
vision/vnrequest/setcomputedevice(_:for:) [Instance Method]
vision/vnrequest/supportedcomputestagedevices [Instance Property]
vision/vnrequest/supportedrevisions [Type Property]
vision/vnrequest/usescpuonly [Instance Property, deprecated]

vision/vnrequestcompletionhandler [Type Alias]

vision/vnrequestfacelandmarksconstellation [Enumeration]
vision/vnrequestfacelandmarksconstellation/constellation65points [Case]
vision/vnrequestfacelandmarksconstellation/constellation76points [Case]
vision/vnrequestfacelandmarksconstellation/constellationnotdefined [Case]
vision/vnrequestfacelandmarksconstellation/init(rawvalue:) [Initializer]

vision/vnrequestprogresshandler [Type Alias]

vision/vnrequestprogressproviding [Protocol]
vision/vnrequestprogressproviding/indeterminate [Instance Property]
vision/vnrequestprogressproviding/progresshandler [Instance Property]

vision/vnrequestrevisionproviding [Protocol]
vision/vnrequestrevisionproviding/requestrevision [Instance Property]

vision/vnrequestrevisionunspecified [Global Variable]

vision/vnrequesttextrecognitionlevel [Enumeration]
vision/vnrequesttextrecognitionlevel/accurate [Case]
vision/vnrequesttextrecognitionlevel/fast [Case]
vision/vnrequesttextrecognitionlevel/init(rawvalue:) [Initializer]

vision/vnrequesttrackinglevel [Enumeration]
vision/vnrequesttrackinglevel/accurate [Case]
vision/vnrequesttrackinglevel/fast [Case]
vision/vnrequesttrackinglevel/init(rawvalue:) [Initializer]

vision/vnsaliencyimageobservation [Class]
vision/vnsaliencyimageobservation/salientobjects [Instance Property]

vision/vnsequencerequesthandler [Class]
vision/vnsequencerequesthandler/init() [Initializer]
vision/vnsequencerequesthandler/perform(_:on:)-3d7nt [Instance Method]
vision/vnsequencerequesthandler/perform(_:on:)-3zt7l [Instance Method]
vision/vnsequencerequesthandler/perform(_:on:)-45e73 [Instance Method]
vision/vnsequencerequesthandler/perform(_:on:)-9jtgj [Instance Method]
vision/vnsequencerequesthandler/perform(_:on:orientation:)-1bkm1 [Instance Method]
vision/vnsequencerequesthandler/perform(_:on:orientation:)-2wvt8 [Instance Method]
vision/vnsequencerequesthandler/perform(_:on:orientation:)-3gcmv [Instance Method]
vision/vnsequencerequesthandler/perform(_:on:orientation:)-6b7rk [Instance Method]
vision/vnsequencerequesthandler/perform(_:onimagedata:) [Instance Method]
vision/vnsequencerequesthandler/perform(_:onimagedata:orientation:) [Instance Method]
vision/vnsequencerequesthandler/perform(_:onimageurl:) [Instance Method]
vision/vnsequencerequesthandler/perform(_:onimageurl:orientation:) [Instance Method]

vision/vnstatefulrequest [Class]
vision/vnstatefulrequest/frameanalysisspacing [Instance Property]
vision/vnstatefulrequest/init(frameanalysisspacing:completionhandler:) [Initializer]
vision/vnstatefulrequest/minimumlatencyframecount [Instance Property]

vision/vntargetedimagerequest [Class]
vision/vntargetedimagerequest/init(targetedcgimage:options:completionhandler:) [Initializer]
vision/vntargetedimagerequest/init(targetedcgimage:orientation:options:completionhandler:) [Initializer]
vision/vntargetedimagerequest/init(targetedciimage:options:completionhandler:) [Initializer]
vision/vntargetedimagerequest/init(targetedciimage:orientation:options:completionhandler:) [Initializer]
vision/vntargetedimagerequest/init(targetedcmsamplebuffer:options:completionhandler:) [Initializer]
vision/vntargetedimagerequest/init(targetedcmsamplebuffer:orientation:options:completionhandler:) [Initializer]
vision/vntargetedimagerequest/init(targetedcvpixelbuffer:options:completionhandler:) [Initializer]
vision/vntargetedimagerequest/init(targetedcvpixelbuffer:orientation:options:completionhandler:) [Initializer]
vision/vntargetedimagerequest/init(targetedimagedata:options:completionhandler:) [Initializer]
vision/vntargetedimagerequest/init(targetedimagedata:orientation:options:completionhandler:) [Initializer]
vision/vntargetedimagerequest/init(targetedimageurl:options:completionhandler:) [Initializer]
vision/vntargetedimagerequest/init(targetedimageurl:orientation:options:completionhandler:) [Initializer]

vision/vntextobservation [Class]
vision/vntextobservation/characterboxes [Instance Property]

vision/vntrackhomographicimageregistrationrequest [Class]
vision/vntrackhomographicimageregistrationrequest/init() [Initializer]
vision/vntrackhomographicimageregistrationrequest/init(completionhandler:) [Initializer]
vision/vntrackhomographicimageregistrationrequest/results [Instance Property]

vision/vntrackhomographicimageregistrationrequestrevision1 [Global Variable]

vision/vntrackingrequest [Class]
vision/vntrackingrequest/inputobservation [Instance Property]
vision/vntrackingrequest/islastframe [Instance Property]
vision/vntrackingrequest/supportednumber(oftrackersandreturnerror:) [Instance Method]
vision/vntrackingrequest/trackinglevel [Instance Property]

vision/vntrackobjectrequest [Class]
vision/vntrackobjectrequest/init(detectedobjectobservation:) [Initializer]
vision/vntrackobjectrequest/init(detectedobjectobservation:completionhandler:) [Initializer]

vision/vntrackobjectrequestrevision1 [Global Variable]

vision/vntrackobjectrequestrevision2 [Global Variable]

vision/vntrackopticalflowrequest [Class]
vision/vntrackopticalflowrequest/computationaccuracy-swift.enum [Enumeration]
vision/vntrackopticalflowrequest/computationaccuracy-swift.enum/high [Case]
vision/vntrackopticalflowrequest/computationaccuracy-swift.enum/init(rawvalue:) [Initializer]
vision/vntrackopticalflowrequest/computationaccuracy-swift.enum/low [Case]
vision/vntrackopticalflowrequest/computationaccuracy-swift.enum/medium [Case]
vision/vntrackopticalflowrequest/computationaccuracy-swift.enum/veryhigh [Case]
vision/vntrackopticalflowrequest/computationaccuracy-swift.property [Instance Property]
vision/vntrackopticalflowrequest/init() [Initializer]
vision/vntrackopticalflowrequest/init(completionhandler:) [Initializer]
vision/vntrackopticalflowrequest/keepnetworkoutput [Instance Property]
vision/vntrackopticalflowrequest/outputpixelformat [Instance Property]
vision/vntrackopticalflowrequest/results [Instance Property]

vision/vntrackopticalflowrequestrevision1 [Global Variable]

vision/vntrackrectanglerequest [Class]
vision/vntrackrectanglerequest/init(rectangleobservation:) [Initializer]
vision/vntrackrectanglerequest/init(rectangleobservation:completionhandler:) [Initializer]

vision/vntrackrectanglerequestrevision1 [Global Variable]

vision/vntracktranslationalimageregistrationrequest [Class]
vision/vntracktranslationalimageregistrationrequest/init() [Initializer]
vision/vntracktranslationalimageregistrationrequest/init(completionhandler:) [Initializer]
vision/vntracktranslationalimageregistrationrequest/results [Instance Property]

vision/vntracktranslationalimageregistrationrequestrevision1 [Global Variable]

vision/vntrajectoryobservation [Class]
vision/vntrajectoryobservation/detectedpoints [Instance Property]
vision/vntrajectoryobservation/equationcoefficients [Instance Property]
vision/vntrajectoryobservation/movingaverageradius [Instance Property]
vision/vntrajectoryobservation/projectedpoints [Instance Property]

vision/vntranslationalimageregistrationrequest [Class]
vision/vntranslationalimageregistrationrequest/results [Instance Property]

vision/vntranslationalimageregistrationrequestrevision1 [Global Variable]

vision/vnvector [Class]
vision/vnvector/dotproduct(of:vector:) [Type Method]
vision/vnvector/init(byadding:to:) [Initializer]
vision/vnvector/init(byaddingvector:tovector:) [Initializer]
vision/vnvector/init(bymultiplying:byscalar:) [Initializer]
vision/vnvector/init(bymultiplyingvector:byscalar:) [Initializer]
vision/vnvector/init(bysubtracting:from:) [Initializer]
vision/vnvector/init(bysubtractingvector:fromvector:) [Initializer]
vision/vnvector/init(coder:) [Initializer]
vision/vnvector/init(r:theta:) [Initializer]
vision/vnvector/init(vectorhead:tail:) [Initializer]
vision/vnvector/init(xcomponent:ycomponent:)-231pv [Initializer]
vision/vnvector/init(xcomponent:ycomponent:)-3p5k3 [Initializer]
vision/vnvector/length [Instance Property]
vision/vnvector/r [Instance Property]
vision/vnvector/squaredlength [Instance Property]
vision/vnvector/theta [Instance Property]
vision/vnvector/unitvector(for:) [Type Method]
vision/vnvector/x [Instance Property]
vision/vnvector/y [Instance Property]
vision/vnvector/zero [Type Property]

vision/vnvideoprocessingoption [Structure, deprecated (renamed: VNVideoProcessor.RequestProcessingOptions)]
vision/vnvideoprocessingoption/framecadence [Type Property, deprecated (renamed: VNVideoProcessor.RequestProcessingOptions)]
vision/vnvideoprocessingoption/init(rawvalue:) [Initializer, deprecated (renamed: VNVideoProcessor.RequestProcessingOptions)]
vision/vnvideoprocessingoption/timeinterval [Type Property, deprecated (renamed: VNVideoProcessor.RequestProcessingOptions)]

vision/vnvideoprocessor [Class]
vision/vnvideoprocessor/add(_:withprocessingoptions:) [Instance Method, deprecated]
vision/vnvideoprocessor/addrequest(_:processingoptions:) [Instance Method]
vision/vnvideoprocessor/analyze(_:) [Instance Method]
vision/vnvideoprocessor/analyze(with:) [Instance Method, deprecated]
vision/vnvideoprocessor/cadence [Class]
vision/vnvideoprocessor/cancel() [Instance Method]
vision/vnvideoprocessor/frameratecadence [Class]
vision/vnvideoprocessor/frameratecadence/framerate [Instance Property]
vision/vnvideoprocessor/frameratecadence/init(_:) [Initializer]
vision/vnvideoprocessor/frameratecadence/init(framerate:) [Initializer]
vision/vnvideoprocessor/init(url:)-38vj9 [Initializer]
vision/vnvideoprocessor/init(url:)-94b7 [Initializer]
vision/vnvideoprocessor/removerequest(_:) [Instance Method]
vision/vnvideoprocessor/requestprocessingoptions [Class]
vision/vnvideoprocessor/requestprocessingoptions/cadence [Instance Property]
vision/vnvideoprocessor/timeintervalcadence [Class]
vision/vnvideoprocessor/timeintervalcadence/init(_:) [Initializer]
vision/vnvideoprocessor/timeintervalcadence/init(timeinterval:) [Initializer]
vision/vnvideoprocessor/timeintervalcadence/timeinterval [Instance Property]

vision/vnvisionversionnumber [Global Variable]
