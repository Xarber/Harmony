#!/usr/bin/env python3
"""Generate an ordinary, dependency-free Xcode project for the iOS/iPadOS app."""
from pathlib import Path
import hashlib
root = Path(__file__).resolve().parent.parent
uid = lambda value: hashlib.sha256(value.encode()).hexdigest()[:24].upper()
objects = {}
def add(name, value):
    objects[uid(name)] = value
    return uid(name)
sources = []
refs = []
for file in sorted((root / 'Sources/HarmonyApp').glob('*.swift')):
    ref = add('ref'+file.name, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "Sources/HarmonyApp/{file.name}"; sourceTree = SOURCE_ROOT;')
    refs.append(ref)
    sources.append(add('build'+file.name, f'isa = PBXBuildFile; fileRef = {ref};'))
asset = add('assets', 'isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Sources/HarmonyApp/Assets.xcassets; sourceTree = SOURCE_ROOT;')
assetBuild = add('assetBuild', f'isa = PBXBuildFile; fileRef = {asset};')
product = add('product', 'isa = PBXFileReference; explicitFileType = wrapper.application; path = Harmony.app; sourceTree = BUILT_PRODUCTS_DIR;')
package = add('package', 'isa = XCLocalSwiftPackageReference; relativePath = .;')
core = add('core', f'isa = XCSwiftPackageProductDependency; package = {package}; productName = HarmonyCore;')
coreBuild = add('coreBuild', f'isa = PBXBuildFile; productRef = {core};')
sourcePhase = add('sourcePhase', 'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ('+','.join(sources)+'); runOnlyForDeploymentPostprocessing = 0;')
releaseRef = add('releaseRef', 'isa = PBXFileReference; lastKnownFileType = text.json; path = Sources/HarmonyApp/Resources/releases.json; sourceTree = SOURCE_ROOT;')
releaseBuild = add('releaseBuild', f'isa = PBXBuildFile; fileRef = {releaseRef};')
resourcePhase = add('resourcePhase', f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({assetBuild},{releaseBuild}); runOnlyForDeploymentPostprocessing = 0;')
frameworkPhase = add('frameworkPhase', f'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ({coreBuild}); runOnlyForDeploymentPostprocessing = 0;')
base = '''CLANG_ENABLE_MODULES = YES; SWIFT_VERSION = 6.0; IPHONEOS_DEPLOYMENT_TARGET = 17.0; SDKROOT = iphoneos; SWIFT_STRICT_CONCURRENCY = complete;'''
projectConfigs=[]; targetConfigs=[]
for name in ['Debug','Release']:
    projectConfigs.append(add('project'+name, f'isa = XCBuildConfiguration; name = {name}; buildSettings = {{ {base} }};'))
    settings = '''PRODUCT_BUNDLE_IDENTIFIER = it.xarber.harmony; PRODUCT_NAME = Harmony; INFOPLIST_FILE = Config/Info.plist; GENERATE_INFOPLIST_FILE = NO; MARKETING_VERSION = 0.1.0; CURRENT_PROJECT_VERSION = 1; HARMONY_COMMIT = development; TARGETED_DEVICE_FAMILY = "1,2"; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; SUPPORTS_MACCATALYST = NO; CODE_SIGN_STYLE = Automatic; ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor; SWIFT_APPROACHABLE_CONCURRENCY = YES;'''
    settings += ' SWIFT_OPTIMIZATION_LEVEL = '+ ('"-Onone"; DEBUG_INFORMATION_FORMAT = dwarf; SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;' if name == 'Debug' else '"-O"; DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";')
    targetConfigs.append(add('target'+name, f'isa = XCBuildConfiguration; name = {name}; buildSettings = {{ {settings} }};'))
pcl = add('pcl','isa = XCConfigurationList; buildConfigurations = ('+','.join(projectConfigs)+'); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
tcl = add('tcl','isa = XCConfigurationList; buildConfigurations = ('+','.join(targetConfigs)+'); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
target = add('target', f'isa = PBXNativeTarget; buildConfigurationList = {tcl}; buildPhases = ({sourcePhase},{frameworkPhase},{resourcePhase}); buildRules = (); dependencies = (); name = Harmony; packageProductDependencies = ({core}); productName = Harmony; productReference = {product}; productType = "com.apple.product-type.application";')
products = add('products', f'isa = PBXGroup; children = ({product}); name = Products; sourceTree = "<group>";')
group = add('group', 'isa = PBXGroup; children = ('+','.join(refs+[asset,releaseRef,products])+'); sourceTree = "<group>";')
project = add('project', f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 2600; }}; buildConfigurationList = {pcl}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; knownRegions = (en,Base); mainGroup = {group}; productRefGroup = {products}; packageReferences = ({package}); projectDirPath = ""; projectRoot = ""; targets = ({target});')
out = root/'Harmony.xcodeproj'; out.mkdir(exist_ok=True)
(out/'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 60; objects = {\n'+'\n'.join(k+' = { '+v+' };' for k,v in objects.items())+f'\n}}; rootObject = {project}; }}\n')
scheme = out/'xcshareddata/xcschemes'; scheme.mkdir(parents=True, exist_ok=True)
(scheme/'Harmony.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="Harmony.app" BlueprintName="Harmony" ReferencedContainer="container:Harmony.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="Harmony.app" BlueprintName="Harmony" ReferencedContainer="container:Harmony.xcodeproj"/></BuildableProductRunnable></LaunchAction><ProfileAction buildConfiguration="Release"/><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>''')
