unit het.Parser;//unssystem het.codeeditor het.cal het.bind unssystem

interface

uses
  windows, sysutils, classes, Variants, Math, typinfo,
  ComObj, OleCtrls, rtti, het.Utils, het.Arrays, het.Variants;

{ array is null nem jo!!!! }

{ $DEFINE power = ^ else power = ** and dereference = ^}
{$DEFINE NullIfNil} //ez valami regi szarsag lesz, mar nem tudom, hogy mi....

// -----------------------------------------------------------------------------
// supported constant syntaxes                                                //
// -----------------------------------------------------------------------------
// -8493028 - int,int64
// 15.4893e-30 - extended
// 0x, $, 0b, 0d - perfixes, postfixes (0x-nel x az exponent)
// 2009.5.21 12:36:05.893849 - date,time
// 0:0 - time only
// 'string'#13#10 - string constants
// "fhudhsu" - string constants
// #$78a67dfc67dfc  //hex string

//inline asm tokens: asm_il() asm_isa()

type
  TAsmMode=(asmNone, asmIL, asmISA);

  TSourceRange=record
    ofs,len:integer;
    function CheckInside(at:integer):boolean;
    function Empty:boolean;
  end;

  EScriptError=class(Exception)
    Category:string;
    FileName:string;
    Line:integer;
    Position:TSourceRange;
    constructor Create(const AMsg,ACategory:string;const AFileName:string='';const ALine:integer=0;const ASrcOfs:integer=0;const ASrcLen:integer=0);
    constructor CreateSimple(const AMsg,ACategory:string);
  end;

  TToken=(tkNone,tkEof,tkWhiteSpace,tkComment,tkIdentifier,tkKeyword,tkConstant,tkSetConstant,
    tkNot,
    tkPlus,tkMinus,
    tkFactorial,
    tkInc,tkDec,tkPostInc,tkPostDec,
    tkReference,tkIndirect,

    {operations}
    tkNullCoalescing,tkZeroCoalescing,tkIs,
    tkPower,
    tkMul,tkDiv,tkIDiv,tkMod,tkIMod,tkAnd,tkShl,tkShr,tkSal,tkSar,
    tkAdd,tkSub,tkOr,tkXor,
    tkConcat,
    tkLike,tkNotLike,tkEqual,tkNotEqual,tkGreater,tkGreaterEqual,tkLess,tkLessEqual,tkIn,tkNotIn,
    tkQuestion,tkColon,tkColonTenary,tkColonNamedVariant,
    tkLet,tkLetAdd,tkLetSub,tkLetMul,tkLetDiv,tkLetPower,tkLetMod,tkLetConcat,tkLambda,

    {other stuff}
    tkDirective,tkPoint,tkPointPoint,tkSemiColon,tkComma,tkBracketOpen,tkBracketClose,tkSqrBracketOpen,tkSqrBracketClose,tkSpecialBracketOpen,tkSpecialBracketClose,

    {keywords}
    tkNop,
    tkRequire,tkBegin,tkEnsure,tkEnd,
    tkIf,tkThen,tkElse,
    tkFor,tkTo,tkDownto,tkTowards,tkDo,tkStep,tkWhere,tkUnless,tkDescending,
    tkWhile,tkRepeat,tkUntil,
    tkCase,tkOf,
    tkWith,tkUsing,

    tkProcedure,tkFunction,tkConstructor,tkDestructor,
    tkVar,tkConst,tkOut,
    tkRaise,

    {variables}
    tk_Field,tk_Funct,tk_Index,

    {assemblers}
    tkAsm_IL,
    tkAsm_ISA,
    tkAsm_InlinePas, //hetpas code inside an asm block ![...]
    tkBackSlash,
    tkAt,

    {macroes}
    tkDoubleHashmark
    );

type
  TTokenSet=set of TToken;

const
  tkPreFixOperation=[tkNot,tkPlus,tkMinus,tkInc,tkDec,tkReference];
  tkPostFixOperation=[tkFactorial,tkIndirect,tkInc,tkDec{replace to postinc,postdec}];

function ParsePascalConstant(var ch:PAnsiChar):variant;overload;
function ParsePascalConstant(const s:ansistring):variant;overload;
function ParsePascalToken(var ch:PAnsiChar;out value:Variant):TToken;

function ParseSkipWhiteSpace(var ch:PAnsiChar):boolean;
function ParseSkipWhitespaceAndComments(var ch:PAnsiChar;const inAsm:boolean=false):boolean;
function ParseIdentifier(var ch:PAnsiChar;out Res:ansistring):boolean;

function ParseCountChars(const AFrom,ATo:pansichar;const AChar:ansichar):integer;overload;
function ParseCountChars(const ASrc:ansistring;const AChar:ansichar):integer;overload;
function ParseRealignLines(const ASrc:ansistring;const AMaxColumns,AFirstLineColumns,ATargetLineCount:integer):ansistring;

//function ParsePascalSyntax(var ch:PAnsiChar):TSyntaxKind;  internal use only
function ParseAsmModeAt(const ACode:ansistring;const APos:integer):TAsmMode;
procedure ParseHighlightPascalSyntax(const ASrc:ansistring;var ADst:ansistring;const AFrom:integer=1;const ATo:integer=$7fffffff;const InitialAsmMode:TAsmMode=asmNone);

type
  TNodeBase=class;
  TNameSpace=class;
  TNameSpaceEntry=class;
  TNameSpaceHetArray=THetArray<TNameSpace>;
  TNameSpaceEntryHetArray=THetArray<TNameSpaceEntry>;
  TObjectHetArray=THetArray<TObject>;
  TNodeParamList=class;
  TNodePostfixOp=class;

  TPropQuery=(pqNone, pqDefault, pqRangeMin, pqRangeMax);

  TContext=class
  private
    nsLocal:TNameSpace;

    RootContext:TContext;
    PrevContext:TContext;

    FParams:TNodeParamList;
    FLocalValues:array of Variant;
    ResultValue:Variant;

    //LocalVariables:array of Variant;
    //postfix conditional variables
    BlockPostfixAssignments:boolean;
    PendingPostfixOperations:THetArray<TNodePostfixOp>;

    FStdOut:AnsiString;//ebbe irogat a writeln
    FStdOutBuilder:IAnsiStringBuilder;

    FExiting, FContinueing:boolean;//exit from namespace
    FBreakCnt:integer;//how many for/while/repeat blocks to break out.

    FPropQuery:TPropQuery;  //alters GetPropValue(), it reports various information about the property.

    procedure SetupOneWith(const AWith:TObject);
    function GetStdOut:ansistring;
  public
    WithStack:TObjectHetArray;

    Constructor Create(const APrevContext:TContext;const ANameSpace:TNameSpace;const AParams:TNodeParamList;const AWithObject:TObject=nil);
    destructor Destroy;override;

    procedure FinalizePostfixOperations(const AFrom:integer);
    function AcquireNameSpaceEntry(const AName:AnsiString;const AIsIndex:boolean;const AParamCount:integer;const ASelfObj:TObject=nil):TNameSpaceEntry;
    function FindContext(const ANameSpace: TNameSpace):TContext;

    procedure StdOutWrite(const s:ansistring);//not threadsafe!
    function Dump:ansistring;

    property StdOut:ansistring read GetStdOut;

    function EvalParamUncached(const AIdx:integer):variant;
    function EvalParam(const AIdx:integer):variant;
    procedure LetParam(const AIdx:integer;const AValue:variant);

    function ParamCount:integer;
    property Param[const Idx:integer]:variant read EvalParam write LetParam;

    function ExecMask:boolean;inline; //tells when to skip instructions, and break out loops
    procedure ExitContext(const AResult:variant);overload;
    procedure ExitContext;overload;
    procedure BreakContext(const blockcnt:integer=$7FFFFFFF{means break all tightly nested if-s});
    procedure ContinueContext;

    property PropQuery:TPropQuery read FPropQuery write FPropQuery;
  end;

  TVariantArray=TArray<Variant>;

  TParameterType=(ptLocal,ptVar,ptConst,ptOut);

  TNameSpaceEntry=class
  private
    FName:ansistring;
    FFullName:AnsiString;
    FNameSpace:TNameSpace;
    FHash:integer;
    FBaseClass:TClass;
    FInfiniteParams:boolean; // pl. write(...)
    FParams:Array of record
      Name:ansistring;
      Default:variant; //empty -> required param
      Typ:TParameterType;
    end;
    FIsIndex:boolean;
    FIsConstructor:boolean;
    procedure ProcessDefinition(const ADefinition:ansistring;const ABaseClass:TClass);
    function ParamListAsVariantArray(const AParamList:TNodeParamList;const AContext:TContext):TVariantArray;
  public
    constructor Create(const ADefinition: ansistring;const ABaseClass:TClass=nil);
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);virtual;
    procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);virtual;
    procedure Ref(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList;const AErrorIfCant:boolean);virtual;

    function ObjectSupported(const AObj:TObject):boolean;
    function ParamCountSupported(const AParamCount:integer):boolean;
    function SelectCompatibleObjectFromWithStack(const AObj:TObject;const AContext:TContext;const mustExists:boolean):TObject;

    property IsIndex:boolean read FIsIndex;
    property IsConstructor:boolean read FIsConstructor;

    function Dump(const AIndent:integer=0):ansistring;virtual;
  end;

  TNameSpaceVariable=class(TNameSpaceEntry)
  private
    FValue:Variant;
  public
    constructor Create(const ADefinition:ansistring;const AValue:Variant);
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Ref(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList;const AErrorIfCant:boolean);override;

    property Value:Variant read FValue write FValue;

    function _ValuePtr:PVariant;
  end;

  TNameSpaceConstant=class(TNameSpaceVariable)
  public
    procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
  end;

  TEvalFunct=reference to function(const AParams:TVariantArray):variant;
  TLetProc=reference to procedure(const AParams:TVariantArray;const AValue:variant);

  TNameSpaceFunction=class(TNameSpaceEntry)
  private
    FEval:TEvalFunct;
    FLet:TLetProc;
  public
    constructor Create(const ADefinition:ansistring;const AEval:TEvalFunct;const ALet:TLetProc=nil);
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
  end;

  TEvalCtxFunct=reference to function(const AContext:TContext;const AParams:TVariantArray):variant;
  TLetCtxProc=reference to procedure(const AContext:TContext;const AParams:TVariantArray;const AValue:variant);

  TNameSpaceCtxFunction=class(TNameSpaceEntry) //same as TNameSpaceFunction but sends Context instead of param array
  private
    FEval:TEvalCtxFunct;
    FLet:TLetCtxProc;
  public
    constructor Create(const ADefinition:ansistring;const AEval:TEvalCtxFunct;const ALet:TLetCtxProc=nil);
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
  end;

  TNameSpaceVectorFunction=class(TNameSpaceFunction)
  public
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
  end;


  TEvalObjectFunct=reference to function(const Obj:TObject;const AParams:TVariantArray):variant;
  TLetObjectProc=reference to procedure(const Obj:TObject;const AParams:TVariantArray;const AValue:variant);

  TNameSpaceObjectFunction=class(TNameSpaceEntry)
  private
    FEval:TEvalObjectFunct;
    FLet:TLetObjectProc;
  public
    constructor Create(const ABaseClass:TClass;const ADefinition:ansistring;const AEval:TEvalObjectFunct;const ALet:TLetObjectProc=nil);
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
  end;

  TObjectConstructFunct=reference to function(const AParams:TVariantArray):TObject;

  TNameSpaceObjectConstructor=class(TNameSpaceEntry)
  private
    FConstructor:TObjectConstructFunct;
  public
    constructor Create(const ABaseClass:TClass;const ADefinition:ansistring;const AConstructor:TObjectConstructFunct);
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
  end;

  TNameSpaceObjectProperty=class(TNameSpaceEntry)
  private
    FPropInfo:PPropInfo;
  public
    constructor Create(const ABaseClass:TClass;const ADefinition:ansistring;const APropInfo:PPropInfo);
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
  end;

  TNameSpaceObjectComponentCache=record
    owner,component:TComponent;
    idx:integer;
  end;
  TNameSpaceObjectComponent=class(TNameSpaceEntry)
  private
    FUnicodeName:string;
    FCache:TNameSpaceObjectComponentCache;
  public
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
  end;

  TNameSpaceVariantInvoker=class(TNameSpaceEntry)//AObj is TObject or VDispatch
  public
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Ref(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList;const AErrorIfCant:boolean);override;
  end;

  TNameSpaceObjectInvoker=class(TNameSpaceEntry)//AObj is TObject Call AObj.IDispatch.Invoke(FName,Params)
  public
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
  end;

  TNameSpaceRTTIMember=class(TNameSpaceEntry)//NewRTTI property or method
  private
    FMember:TRttiMember;
  public
    constructor Create(const ARTTIMember:TRttiMember);
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
//    procedure Ref(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList;const AErrorIfCant:boolean);virtual;
  end;

  TNameSpaceLocalVariable=class(TNameSpaceEntry)
  private
    FIndex:integer;
  public
    constructor Create(const ADefinition: ansistring;const AIndex:integer);
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Ref(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList;const AErrorIfCant:boolean);override;
  end;

  TNameSpaceParameter=class(TNameSpaceEntry)
  private
    FIndex:Integer;
    FDefault:variant;
    FType:TParameterType;
    FCacheable:boolean;
  public
    constructor Create(const ADefinition: ansistring;const AIndex:integer;const ADefault:variant;const AType:TParameterType);
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Ref(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList;const AErrorIfCant:boolean);override;
  end;

  TNameSpaceResult=class(TNameSpaceEntry)
  public
    constructor Create(const AName: ansistring);
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
    procedure Ref(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList;const AErrorIfCant:boolean);override;
  end;

  TNameSpaceScriptFunction=class(TNameSpaceEntry)
  private
    FProcNameSpace:TNameSpace;
    FBody:TNodeBase;
    FLocalValueCount:integer;
  public
    constructor Create(const ADefinition:ansistring;const ANameSpace:TNameSpace;const ABody:TNodeBase);
    destructor Destroy;override;
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;

    function Dump(const AIndent:integer=0):ansistring;override;
  end;

  TNameSpace=class
  private
    FName:AnsiString;
    FList:TNameSpaceEntryHetArray;
    FParent:TNameSpace;
    FModuleFileName:string;
    function GetFullName:AnsiString;
    procedure ErrorAlreadyExists(const AName:ansistring);
  public
    nsUses:THetArray<TNameSpace>;
    property Name:AnsiString read FName;
    property FullName:AnsiString read GetFullName;
    constructor Create(const AName:ansistring);
    destructor Destroy;override;
    function FindByHash(const AHash:integer):TNameSpaceEntry;
    function FindByName(const AName:ansistring):TNameSpaceEntry;

    function FindByHashReqursive(const AHash:integer):TNameSpaceEntry;
    function FindByNameReqursive(const AName:ansistring):TNameSpaceEntry;

    procedure Add(const AEntry: TNameSpaceEntry);
    procedure AddOrFree(const AEntry:TNameSpaceEntry);

    procedure AddVariable(const ADefinition:ansistring;const AValue:variant);
    procedure AddConstant(const ADefinition:ansistring;const AValue:variant);
    procedure AddFunction(const ADefinition:ansistring;const AEval:TEvalFunct;const ALet:TLetProc=nil);overload;
    procedure AddFunction(const ADefinition:ansistring;const AEval:TEvalCtxFunct;const ALet:TLetCtxProc=nil);overload;
    procedure AddVectorFunction(const ADefinition:ansistring;const AEval:TEvalFunct;const ALet:TLetProc=nil);
    procedure AddObjectFunction(const ABaseClass:TClass;const ADefinition:ansistring;const AEval:TEvalObjectFunct;const ALet:TLetObjectProc=nil);
    procedure AddDefaultObjectFunction(const ABaseClass:TClass;const ADefinition:ansistring;const AEval:TEvalObjectFunct;const ALet:TLetObjectProc=nil);
    procedure AddEnum(const ATypeInfo:PTypeInfo);
    procedure AddSet(const ATypeInfo:PTypeInfo);
    procedure AddClass(const AClass:TClass);
    procedure AddObjectConstructor(const ABaseClass:TClass;const ADefinition:ansistring;const AConstr:TObjectConstructFunct);

    procedure AddUses(const AUses:TNameSpace);overload;
    procedure AddUses(const AUses:ansistring);overload;
    procedure AddUses(const AUses:array of const);overload;

    procedure Delete(const AName:ansistring;const ErrorWhenNotFound:boolean=false);

    function Dump(const AIndent:integer=0):ansistring;
    function WordList:TArray<ansistring>;
  end;

  TNodeBase=class
  private
    //FSourceRange:TSourceRange;
  public
    procedure FreeSubNodes;
    procedure Eval(const AContext:TContext;var AResult:variant);overload;virtual;abstract;
    function Eval(const AContext:TContext):variant;overload;
    procedure Let(const AContext:TContext;const AValue:Variant);virtual;
    procedure Ref(const AContext:TContext;const AErrorIfCant:boolean;var AResult:variant);overload;virtual;
    function Ref(const AContext:TContext;const AErrorIfCant:boolean):variant;overload;
    function RefPtr(const AContext:TContext):PVariant;overload;
    function RefPtr(const AContext:TContext;var tmp:variant):PVariant;overload;

    function SubNodeCount:integer;virtual;abstract;
    function SubNode(const n:integer):TNodeBase;virtual;abstract;
    procedure SetSubNode(const n:integer;const ANode:TNodeBase);virtual;abstract;
    function Dump(const AIndent:integer=0):ansistring;virtual;abstract;
    function Clone:TNodeBase;virtual;

    destructor Destroy;override;
  end;

  TNodeBaseClass=class of TNodeBase;

  TNodeLeaf=class(TNodeBase) //node with 0 subnodes
  private
  public
    function SubNodeCount:integer;override;
    function SubNode(const n:integer):TNodeBase;override;
    procedure SetSubNode(const n:integer;const ANode:TNodeBase);override;
    function Dump(const AIndent:integer=0):ansistring;override;
  end;

  TNodeOp=class(TNodeBase)
  private
  public
    class function Priority:integer;virtual;
  end;

  TNode1Op=class(TNodeOp)
  private
    FOp1:TNodeBase;
  public
    function SubNodeCount:integer;override;
    function SubNode(const n:integer):TNodeBase;override;
    procedure SetSubNode(const n:integer;const ANode:TNodeBase);override;
    function Dump(const AIndent:integer=0):ansistring;override;
  end;

  TNode2Op=class(TNodeOp)
  private
    FOp1,FOp2:TNodeBase;
  public
    function SubNodeCount:integer;override;
    function SubNode(const n:integer):TNodeBase;override;
    procedure SetSubNode(const n:integer;const ANode:TNodeBase);override;
    function Dump(const AIndent:integer=0):ansistring;override;
  end;

  TNodeManyOp=class(TNodeOp) //general node
  private
    FSubNodes:THetArray<TNodeBase>;
  public
    function SubNodeCount:integer;override;
    function SubNode(const n:integer):TNodeBase;override;
    procedure SetSubNode(const n:integer;const ANode:TNodeBase);override;
    function AddSubNode(const n:TNodeBase):TNodeBase;
    function Dump(const AIndent:integer=0):ansistring;override;
  end;

  TNodeParamList=class(TNodeManyOp)
  public
    procedure Eval(const AContext:TContext;var AResult:variant);override;

    procedure EvalParam(const AContext:TContext;var AResult:variant;const idx:integer);overload;
    function EvalParam(const AContext:TContext;const idx:integer):variant;overload;
    function ParamCount:integer;
    procedure EnsureParamCount(const ACnt:integer;const msg:ansistring);overload;
    procedure EnsureParamCount(const AMin,AMax:integer;const msg:ansistring);overload;
  end;

  TNodeConstant=class(TNodeLeaf)
  private
    FValue:variant;
  public
    constructor Create(const AValue:Variant);
    function Dump(const AIndent:integer=0):ansistring;override;
    function Clone:TNodeBase;override;
    property Value:variant read FValue write FValue;
    procedure Eval(const AContext:TContext;var AResult:variant);override;
  end;

  TNodeConstantExpr=class(TNode1Op)
  private
    FValue:variant;
    FEvaluated:boolean;
  public
    constructor Create(const AExpr:TNodeBase);
    function Dump(const AIndent:integer=0):ansistring;override;
    function Clone:TNodeBase;override;
    property Value:variant read FValue write FValue;
    procedure Eval(const AContext:TContext;var AResult:variant);override;
  end;

  TNodeIdentifier=class(TNodeLeaf) //subnode: parameters
  private
    FIdName:ansistring;
    FIdHash:integer;
    FNameSpaceEntry:TNameSpaceEntry;
    procedure SetIdName(const Value: ansistring);
  public
    constructor Create(const AName:ansistring);
    function Dump(const AIndent:integer=0):ansistring;override;
    function Clone:TNodeBase;override;
    procedure Eval(const AContext:TContext;var AResult:variant);override;
    procedure Let(const AContext:TContext;const AValue:Variant);override;
    procedure Ref(const AContext:TContext;const AErrorIfCant:boolean;var AResult:variant);override;

    property IdName:ansistring read FIdName write SetIdName;
    property IdHash:integer read FIdHash;
  end;

  TNode_Funct           =class(TNode2Op)
  private
    FNameSpaceEntry:TNameSpaceEntry;
    procedure UpdateNSE_GetSelfObj(const AContext:TContext;out ASelfObj:TObject);
  public
    procedure Eval(const AContext:TContext;var AResult:variant);override;
    procedure Let(const AContext:TContext;const AValue:Variant);override;
  end;

  TNode_Index           =class(TNode2Op)
  private
    FNameSpaceEntry,FNameSpaceEntry2:TNameSpaceEntry;
    procedure UpdateNSE_GetSelfObj(const AContext:TContext;out ASelfObj:TObject);
  public
    procedure Eval(const AContext:TContext;var AResult:variant);override;
    procedure Let(const AContext:TContext;const AValue:Variant);override;
    procedure Ref(const AContext:TContext;const AErrorIfCant:boolean;var AResult:variant);override;
  end;

  TNodeNop=class(TNodeLeaf)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;

  TNodePlus             =class(TNode1Op)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeMinus            =class(TNode1Op)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeNot              =class(TNode1Op)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeFactorial        =class(TNode1Op)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeInc              =class(TNode1Op)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeDec              =class(TNode1Op)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeReference        =class(TNode1Op)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeIndirect         =class(TNode1Op)public procedure Eval(const AContext:TContext;var AResult:variant);override;
                                               procedure Ref(const AContext:TContext;const AErrorIfCant:boolean;var AResult:variant);override; end;

  //PostFixOperations must handle ctx.BlockPostfixAssignments and update PostfixOperationStack array
  TNodePostfixOp        =class(TNode1Op)public procedure PostfixFinalize(const AContext:TContext);virtual;abstract;end;
  TNodePostInc          =class(TNodePostfixOp)public
                           procedure Eval(const AContext:TContext;var AResult:variant);override;
                           procedure PostfixFinalize(const AContext:TContext);override;
                         end;
  TNodePostDec          =class(TNodePostfixOp)public
                           procedure Eval(const AContext:TContext;var AResult:variant);override;
                           procedure PostfixFinalize(const AContext:TContext);override;
                         end;

  TPrio12=class(TNode2Op)public class function Priority:integer;override;end;
  TPrio11=class(TNode2Op)public class function Priority:integer;override;end;
  TPrio10=class(TNode2Op)public class function Priority:integer;override;end;
  TPrio9 =class(TNode2Op)public class function Priority:integer;override;end;
  TPrio8 =class(TNode2Op)public class function Priority:integer;override;end;
  TPrio7 =class(TNode2Op)public class function Priority:integer;override;end;
  TPrio6 =class(TNode2Op)public class function Priority:integer;override;end;
  TPrio5 =class(TNode2Op)public class function Priority:integer;override;end;
  TPrio4 =class(TNode2Op)public class function Priority:integer;override;end;
  TPrio3 =class(TNode2Op)public class function Priority:integer;override;end;

  TNode_Field           =class(TPrio12)
  private
    FNameSpaceEntry:TNameSpaceEntry;{object}
//    FNullSafe:boolean;
    procedure UpdateNSE_GetSelfObj(const AContext:TContext;out ASelfObj:TObject;var tmp:variant);
  public
    procedure Eval(const AContext:TContext;var AResult:variant);override;
    procedure Let(const AContext:TContext;const AValue:Variant);override;
    procedure Ref(const AContext:TContext;const AErrorIfCant:boolean;var AResult:variant);override;
  end;

  TNodeNamedVariant     =class(TPrio11)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;

  TNodeNullCoalescing   =class(TPrio10)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeZeroCoalescing   =class(TPrio10)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeIs               =class(TPrio10)public invert:boolean; procedure Eval(const AContext:TContext;var AResult:variant);override;end;

  TNodePower            =class(TPrio9 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;

  TNodeMul              =class(TPrio8 )public procedure Eval(const AContext:TContext;var AResult:variant);override;procedure Let(const AContext:TContext;const AValue:variant);override;end;
  TNodeDiv              =class(TPrio8 )public procedure Eval(const AContext:TContext;var AResult:variant);override;procedure Let(const AContext:TContext;const AValue:variant);override;end;
  TNodeIDiv             =class(TPrio8 )public procedure Eval(const AContext:TContext;var AResult:variant);override;procedure Let(const AContext:TContext;const AValue:variant);override;end;
  TNodeMod              =class(TPrio8 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeIMod             =class(TPrio8 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeAnd              =class(TPrio8 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeShl              =class(TPrio8 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeShr              =class(TPrio8 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeSal              =class(TPrio8 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeSar              =class(TPrio8 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;

  TNodeAdd              =class(TPrio7 )public procedure Eval(const AContext:TContext;var AResult:variant);override;procedure Let(const AContext:TContext;const AValue:variant);override;end;
  TNodeSub              =class(TPrio7 )public procedure Eval(const AContext:TContext;var AResult:variant);override;procedure Let(const AContext:TContext;const AValue:variant);override;end;
  TNodeOr               =class(TPrio7 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeXor              =class(TPrio7 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;

  TNodeConcat           =class(TPrio6 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;

  TNodeLike             =class(TPrio5 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeNotLike          =class(TNodeLike)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeIn               =class(TPrio5 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeNotIn            =class(TNodeIn)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeRelation         =class(TPrio5)public procedure Eval(const AContext:TContext;var AResult:variant);override;
                                             function RelationF(const a,b:variant):boolean;
                                             function EvalReturnRightOp(const AContext: TContext; var AResult: Variant):boolean;
                                                    procedure Relation(var a:variant;const b:variant);virtual;abstract;end;
  TNodeEqual            =class(TNodeRelation)public procedure Relation(var a:variant;const b:variant);override;end;
  TNodeNotEqual         =class(TNodeRelation)public procedure Relation(var a:variant;const b:variant);override;end;
  TNodeGreater          =class(TNodeRelation)public procedure Relation(var a:variant;const b:variant);override;end;
  TNodeGreaterEqual     =class(TNodeRelation)public procedure Relation(var a:variant;const b:variant);override;end;
  TNodeLess             =class(TNodeRelation)public procedure Relation(var a:variant;const b:variant);override;end;
  TNodeLessEqual        =class(TNodeRelation)public procedure Relation(var a:variant;const b:variant);override;end;

  TNodeTenary           =class(TPrio4 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeTenaryChoices    =class(TPrio4 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;

  TNodeLet              =class(TPrio3 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeLetAdd           =class(TPrio3 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeLetSub           =class(TPrio3 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeLetMul           =class(TPrio3 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeLetDiv           =class(TPrio3 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeLetPower         =class(TPrio3 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeLetMod           =class(TPrio3 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeLetConcat        =class(TPrio3 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeLambda           =class(TPrio3 )public procedure Eval(const AContext:TContext;var AResult:variant);override;end;

  TNodeRange            =class(TNode2Op)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeSetConstruct     =class(TNodeManyOp)
  public
    procedure Eval(const AContext:TContext;var AResult:variant);override;
    function EvalContains(const AValue:variant;const AContext:TContext):boolean;
    function EvalIsWild(const AValue:ansistring;const AContext:TContext):boolean;
  end;

  TNodeArrayConstruct   =class(TNodeManyOp)
  public
    procedure Eval(const AContext:TContext;var AResult:variant);override;
    procedure Let(const AContext:TContext;const AValue:Variant);override;
  end;

//executed things

  TNodeSequence         =class(TNodeManyOp)
  private
    FRequire,FEnsure:TNodeBase;
  public
    destructor Destroy;override;
    procedure Eval(const AContext:TContext;var AResult:variant);override;
  end;

  TNodeWith             =class(TNodeManyOp)public isUsing:boolean; procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeIf               =class(TNodeManyOp)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;

  TNodeRaise            =class(TNode1Op)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;

  TNodeIteration        =class(TNodeManyOp)
  private
    FTightlyNested:boolean;//If yes, then this iteration will not decrease breakcnt
                           //eg: for i:=0 to 1 do for j:=1 to 2 do break;
                           //    ^^ this for will decrement breakcnt, not the inner one
    procedure HandleBreak(const AContext:TContext);inline; //decrements breakcnt if can
  end;

  TNodeRepeat           =class(TNodeIteration)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeWhile            =class(TNodeIteration)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;
  TNodeFor              =class(TNodeIteration)
  private
  type
    TForType=(ftTo,ftDownTo,ftTowards,ftIn);
  var
    FForType:TForType;
    FDescending:Boolean;
  public
    procedure Eval(const AContext:TContext;var AResult:variant);override;
    function Clone:TNodeBase;override;
  end;
  TNodeCase             =class(TNodeManyOp)public procedure Eval(const AContext:TContext;var AResult:variant);override;end;

  TNodeInlineAsm=class(TNodeManyOp)
  private
    FMode:TAsmMode;
    FCode:ansistring;
    FInsertPos:TArray<integer>;//ezekre a poziciokra kell beszurni az evalualt subnodeokat stringkent
  public
    procedure Eval(const AContext:TContext;var AResult:variant);override;
  end;

function CompilePascalProgram(const ASrc:ansistring;const ALocalNS:TNameSpace):TNodeBase;

function VarIsInvokeable(const V:variant):boolean;

procedure RegisterNameSpace(const ns:TNameSpace);
procedure UnRegisterNameSpace(const ns:TNameSpace);

function Eval(const AExpr:ansistring;const AWith:TObject=nil;const APropQuery:TPropQuery=pqNone):variant;
procedure Let(const AExpr:ansistring;const AValue:variant;const AWith:TObject=nil);
function PropQuery(const APropQuery:TPropQuery;const AExpr:ansistring;const AWith:TObject=nil):variant;

//helper interfaces
type
  IExpr=interface
    function Eval(const AWith:TObject=nil):variant;
    procedure Let(const AValue:variant;const AWith:TObject=nil);

    function _Node:TNodeBase;
    function _NameSpace:TNameSpace;
    function _Context:TContext;
  end;

  TExpr=class(TInterfacedObject,IExpr)
  private
    FNode:TNodeBase;
    FNameSpace:TNameSpace;
    FContext:TContext;
  public
    constructor Create(const AExpr:ansistring;const AUses:array of const;const AModuleFileName:string='');
    destructor Destroy;override;

    function Eval(const AWith:TObject=nil):variant;
    procedure Let(const AValue:variant;const AWith:TObject=nil);

    procedure FreeNode;
    procedure AppendNode(const ANode:TNodeBase);
    procedure AppendCode(const AExpr:ansistring);

    function _Node:TNodeBase;
    function _NameSpace:TNameSpace;
    function _Context:TContext;
  end;

function CompileExpr(const AExpr:ansistring;const AUses:array of const;const AModuleFileName:string=''):IExpr;overload;
function CompileExpr(const AExpr:ansistring;const AUses:TNameSpace=nil;const AModuleFileName:string=''):IExpr;overload;

function DumpProperties(const AObj:TObject;const APropNameList:AnsiString):AnsiString;


type
  _TInlineAsmSyntaxProc=function(const AIdentifier:ansistring):TSyntaxKind;

var
  _Asm_il_syntax:_TInlineAsmSyntaxProc;
  _Asm_isa_syntax:_TInlineAsmSyntaxProc;

// Vector operations

const
  opInc                 =32;
  opDec                 =33;
  opFloatModulus        =34;
  opPower               =35;
  opShiftRightSigned    =36;
  opConcat              =37;//used in nsSystem.Aggregate()

procedure _vArrayOp_Access(const a:variant;out p:PVariant;out len:Integer);
procedure vOp(const Op:TVarOp;var A:variant);overload;
procedure vOp(const Op:TVarOp;var A:variant;const b:variant);overload;

//---------------------------------------------------------------------------

var
  _SystemNamespace:TNameSpace=nil;

implementation

uses het.Objects;

var
  rtticontext:TRttiContext; //global context for newrtti

// -----------------------------------------------------------------------------
// Exceptions                                                                 //
// -----------------------------------------------------------------------------

constructor EScriptError.Create;
var s:string;
begin
  s:=switch(ACategory<>'','['+ACategory+'] ')+
     extractfilename(AFileName)+
     switch(ALine>0,'('+tostr(ALine)+')');
  if s<>'' then s:=s+': ';
  s:=s+AMsg;

  inherited Create(s);
  Category:=ACategory;
  FileName:=AFileName;
  Line:=ALine;
  Position.Ofs:=ASrcOfs;
  Position.Len:=ASrcLen;
end;

constructor EScriptError.CreateSimple;
begin
  inherited Create(AMsg);
  Category:=ACategory;
end;

procedure ParserError(const msg:AnsiString);
begin
  raise EScriptError.CreateSimple(msg,'Parser Error');
end;

procedure CompileError(const msg:AnsiString);
begin
  raise EScriptError.CreateSimple(msg,'Compiler Error');
end;

procedure NameSpaceError(const msg:AnsiString);
begin
  raise EScriptError.CreateSimple(msg,'NameSpace Error');
end;

procedure ExecError(const msg:AnsiString);
begin
  raise EScriptError.CreateSimple(msg,'Exec Error');
end;



function TSourceRange.CheckInside(at:integer):boolean;
begin
  result:=(ofs>=at)and(ofs+len<=at);
end;

function TSourceRange.Empty: boolean;
begin
  result:=(ofs=0)and(len=0);
end;

function DumpProperties;var act:AnsiString;
begin
  with AnsiStringBuilder(result,true)do
    for act in ListSplit(APropNameList,',')do
      AddStr(act+':='+VariantToPas(Eval(act,AObj))+';'#13#10);
end;

constructor TExpr.Create(const AExpr:ansistring;const AUses:array of const;const AModuleFileName:string='');
var i:integer;
    s:ansistring;
begin
  inherited Create;

  s:=ChangeFileExt(ExtractFileName(AModuleFileName),'');
  if s='' then s:='unnamed';

  FNameSpace:=TNameSpace.Create(s);
  FNameSpace.AddUses(AUses);
  FNameSpace.FModuleFileName:=AModuleFileName;

  if _SystemNamespace<>nil then
    if not FNameSpace.nsUses.Find(function(const a:TNameSpace):boolean begin result:=a=_SystemNamespace end,i)then
      FNameSpace.nsUses.Insert(_SystemNamespace,0);

  FNode:=CompilePascalProgram(AExpr,FNameSpace);// <- exception can abort this constructor

  FContext:=TContext.Create(nil,FNameSpace,nil,nil);
end;

procedure TExpr.FreeNode;
begin
  FreeAndNil(FNode);
end;

procedure TExpr.AppendNode(const ANode:TNodeBase);
var seq:TNodeSequence;
begin
  if ANode=nil then exit;
  if FNode=nil then
    FNode:=ANode
  else begin
    if (FNode is TNodeSequence)then
      seq:=TNodeSequence(FNode)
    else begin
      seq:=TNodeSequence.Create;
      seq.AddSubNode(FNode);
      FNode:=seq;
    end;
    seq.AddSubNode(ANode);
  end;
end;

procedure TExpr.AppendCode(const AExpr:ansistring);
begin
  AppendNode(CompilePascalProgram(AExpr,FNameSpace));
end;

destructor TExpr.Destroy;
begin
  FreeAndNil(FNode);
  FreeAndNil(FNameSpace);
  FreeAndNil(FContext);
  inherited;
end;

function TExpr.Eval(const AWith:TObject=nil):variant;
begin
  FContext.SetupOneWith(AWith);
  if FNode<>nil then FNode.Eval(FContext,Result)
                else Result:=Null;// raise EExecError.Create('Error evaluating an empty expr.');
end;

procedure TExpr.Let(const AValue:variant;const AWith:TObject=nil);
begin
  FContext.SetupOneWith(AWith);
  if FNode<>nil then FNode.Let(FContext,AValue)
                else ExecError('TExpr.Let() Error assigning value to an empty node.');
end;

function TExpr._Context: TContext;
begin
  result:=FContext;
end;

function TExpr._NameSpace: TNameSpace;
begin
  result:=FNameSpace;
end;

function TExpr._Node: TNodeBase;
begin
  if self=nil then Result:=nil
              else Result:=FNode;
end;

function CompileExpr(const AExpr:ansistring;const AUses:array of const;const AModuleFileName:string=''):IExpr;
begin
  result:=TExpr.Create(AExpr,AUses,AModuleFileName);
end;

function CompileExpr(const AExpr:ansistring;const AUses:TNameSpace=nil;const AModuleFileName:string=''):IExpr;overload;
begin
  if AUses=nil then result:=TExpr.Create(AExpr,[]     ,AModuleFileName)
               else result:=TExpr.Create(AExpr,[AUses],AModuleFileName);
end;

function Eval(const AExpr:ansistring;const AWith:TObject=nil;const APropQuery:TPropQuery=pqNone):variant;
var ns:TNameSpace;
    ctx:TContext;
    n:TNodeBase;
begin
  if AExpr='' then exit(Unassigned);

  ns:=TNameSpace.Create('eval');
  if _SystemNamespace<>nil then ns.nsUses.Append(_SystemNamespace);
  ctx:=TContext.Create(nil,ns,nil,AWith);
  ctx.PropQuery:=APropQuery;
  n:=nil;
  try
    n:=CompilePascalProgram(AExpr,ns);
    if n<>nil then n.Eval(ctx,Result)
              else result:=Unassigned;
  finally
    n.Free;
    ctx.Free;
    ns.Free;
  end;
end;

function PropQuery(const APropQuery:TPropQuery;const AExpr:ansistring;const AWith:TObject=nil):variant;
begin
  try
    result:=Eval(AExpr,AWith,APropQuery);
  except
    result:=Null;
  end;
end;

procedure Let(const AExpr:ansistring;const AValue:variant;const AWith:TObject=nil);
var ns:TNameSpace;
    ctx:TContext;
    n:TNodeBase;
begin
  if AExpr='' then exit;

  ns:=TNameSpace.Create('eval');
  if _SystemNamespace<>nil then ns.nsUses.Append(_SystemNamespace);
  ctx:=TContext.Create(nil,ns,nil,AWith);
  n:=nil;
  try
    n:=CompilePascalProgram(AExpr,ns);
    if n<>nil then
      n.Let(ctx,AValue);
  finally
    n.Free;
    ctx.Free;
    ns.Free;
  end;
end;


function OptVarIsZero(const V:Variant):boolean;inline;
begin
  result:=(TVarData(V).VType and(varTypeMask+varArray)<($10F){CFirstUserType})and(V=0);
end;

var
  nsObjectProperties:TNameSpace;//global, caching propinfoes
  nsVariantInvoker:TNameSpace;//global, caching Dispatch calls
  nsRegistered:THetArray<TNameSpace>;

function FindRegisteredNameSpaceIndex(const ns:TNameSpace):integer;
begin
  if not nsRegistered.Find(function(const a:TNameSpace):boolean begin result:=ns=a end,result)then result:=-1;;
end;

function FindRegisteredNameSpaceIndexByName(const name:ansistring):integer;
begin
  if not nsRegistered.Find(function(const a:TNameSpace):boolean begin result:=cmp(a.Name,name)=0 end,result)then result:=-1;
end;

function FindRegisteredNameSpaceByName(const name:ansistring):TNameSpace;
var i:integer;
begin
  i:=FindRegisteredNameSpaceIndexByName(name);
  if i>=0 then result:=nsRegistered.FItems[i]
          else result:=nil;
end;

procedure RegisterNameSpace(const ns:TNameSpace);
begin
  if ns=nil then exit;
  if ns.Name='' then raise Exception.Create('Unable to registen an unnamed namespace');
  if FindRegisteredNameSpaceIndex(ns)>=0then Exception.Create('Namespace already registered "'+ns.name+'"');
  if FindRegisteredNameSpaceIndexByName(ns.Name)>=0then raise Exception.Create('Another namespace with the same name already exists "'+ns.name+'"');
  nsRegistered.Append(ns);
end;

procedure UnRegisterNameSpace(const ns:TNameSpace);
var idx:integer;
begin
  idx:=FindRegisteredNameSpaceIndex(ns);
  if idx<0 then raise Exception.Create('UnRegisterNameSpace() Cannot find namespace');
  nsRegistered.Remove(idx);
end;

procedure FreeRegisteredNameSpaces;
var i:integer;
begin with nsRegistered do begin
  for i:=FCount-1 downto 0 do FItems[i].Free;
  Clear;
end;end;

const
  GUID_NULL:TGUID=   '{00000000-0000-0000-0000-000000000000}';
  IID_DISPATCH:TGuid='{00020400-0000-0000-C000-000000000046}';

type
  TDispatchKind=(dkMethod,dkPropertyGet,dkPropertySet,dkGetReference{named variant value reference});
  TFakeCustomVariantType=class(TCustomVariantType);

const
  MaxDispArgs=32;

const
  DISPATCH_METHOD         = $1;
  DISPATCH_PROPERTYGET    = $2;
  DISPATCH_PROPERTYPUT    = $4;
  DISPATCH_PROPERTYPUTREF = $8;
  DISPATCH_CONSTRUCT      = $4000;

function MyDispatchInvoke(const ADisp:IDispatch;const ADispatchKind:TDispatchKind;const AName:ansistring;const AParams:TVariantArray):Variant;
var i:integer;
    p:array of PVariant;
    cd:RawByteString;
    DispIDs:integer;//only one, no namedparam support
begin
  if ADisp=nil then ExecError('Cannot invoke IDispatch(nil).'+AName);
  if AName='' then ExecError('Cannot invoke IDispatch.[noname]');
  if length(AParams)>255 then ExecError('Too many parameters in IDispatch.'+AName);

  //assemble params
  setlength(p,length(AParams));
  setlength(cd,3+length(AParams));
  for i:=0 to high(AParams)do begin
    case(TVarData(AParams[i]).VType and not varByRef)of
      varUString:AParams[i]:=ansistring(AParams[i]);
    end;
    p[i]:=@AParams[i];
    cd[i+4]:=ansichar(varVariant or $80{whatever it is});
  end;

  case ADispatchKind of
    dkMethod:cd[1]:=ansichar(DISPATCH_METHOD);
    dkPropertyGet:cd[1]:=ansichar(DISPATCH_PROPERTYGET);
    dkPropertySet:cd[1]:=ansichar(DISPATCH_PROPERTYPUT);
    else cd[1]:=#0;
  end;
  cd[2]:=ansichar(length(AParams));//params
  cd[3]:=#0;//namedparams

  //get nameID
  if AName[1] in ['0'..'9','-']then begin
    DispIDs:=StrToInt(AName);
  end else begin
    i:=ADisp.GetIDsOfNames(GUID_NULL,PWideChar(WideString(AName)),1,0{GetThreadLocale},@DispIds);
    if i=Integer(DISP_E_UNKNOWNNAME) then ExecError('Unknown IDispatch.name: '+toPas(AName))
      else OleCheck(i);
  end;
  DispatchInvoke(ADisp,PCallDesc(cd),@DispIDs,pointer(P),@Result);
end;

type
  TVariantInvoker=class(TObject)
  private
    FVariant:Variant;
  public
    constructor Create(const AVariant:variant);
    function Invoke(const ADispatchKind:TDispatchKind;const AName:ansistring;const AParams:TVariantArray):variant;
  end;

constructor TVariantInvoker.Create(const AVariant: Variant);
begin
  FVariant:=AVariant;
end;

function TVariantInvoker.Invoke(const ADispatchKind:TDispatchKind;const AName:ansistring;const AParams:TVariantArray):variant;
var i:integer;
    cd:rawbytestring;
    Custom:TCustomVariantType;
    Source:PVarData;
    p:array of PVariant;
    pv:PVariant;
begin
  //solve byRefs
  Result:=Unassigned;

  Source:=@FVariant;
  while Source^.VType = varByRef or varVariant do
    Source:=Source^.VPointer;

  if VarIsReference(PVariant(Source)^) then
    PVariant(Source):=VarDereference(PVariant(Source)^);

  if VarIsArray(PVariant(Source)^) then begin //VarArray with named items
    case ADispatchKind of
      dkMethod,dkPropertyGet:begin
        if length(AParams)>0 then raise EVariantInvalidArgError.Create('TVariantInvoker: Too many actual parameters varArray.'+AName);
        for i:=VarLow(PVariant(Source)^)to VarHigh(PVariant(Source)^)do begin
          pv:=VarArrayAccess(PVariant(Source)^,i);
          if VarIsNamed(pv^) then
            if cmp(VarNamedGetName(pv^),AName)=0 then
              exit(VarNamedGetValue(pv^));
        end;
      end;
      dkPropertySet:begin
        if length(AParams)<>1 then raise EVariantInvalidArgError.Create('TVariantInvoker: Need a value to assign property varArray.'+AName);
        for i:=VarLow(PVariant(Source)^)to VarHigh(PVariant(Source)^)do begin
          pv:=VarArrayAccess(PVariant(Source)^,i);
          if VarIsNamed(pv^) then
            if cmp(VarNamedGetName(pv^),AName)=0 then begin
              VarNamedSetValue(pv^,AParams[0]);
              exit;
            end;
        end;
      end;
      dkGetReference:begin
        if length(AParams)>0 then raise EVariantInvalidArgError.Create('TVariantInvoker: Too many actual parameters varArray.'+AName);
        for i:=VarLow(PVariant(Source)^)to VarHigh(PVariant(Source)^)do begin
          pv:=VarArrayAccess(PVariant(Source)^,i);
          if VarIsNamed(pv^) then
            if cmp(VarNamedGetName(pv^),AName)=0 then begin
              Result:=VReference(VarNamedRefValue(pv^));
              exit;
            end;
        end;
      end;
    end;
  end else begin //IDispatch
    //assemble params
    setlength(p,length(AParams));
    setlength(cd,3+length(AParams));
    for i:=0 to high(AParams)do begin
      case(TVarData(AParams[i]).VType and not varByRef)of
        varUString:AParams[i]:=ansistring(AParams[i]);
      end;
      p[i]:=@AParams[i];
      cd[i+4]:=ansichar(varVariant or $80{whatever it is});
    end;

    //calldesc header
    case ADispatchKind of
      dkMethod:cd[1]:=ansichar(DISPATCH_METHOD);
      dkPropertyGet:cd[1]:=ansichar(DISPATCH_PROPERTYGET);
      dkPropertySet:cd[1]:=ansichar(DISPATCH_PROPERTYPUT);
      else cd[1]:=#0;
    end;
    cd[2]:=ansichar(length(AParams));//params
    cd[3]:=#0;//namedparams
    cd:=cd+AName; //methodname,  no namedparam support yet

    case Source^.VType of
      varDispatch,
      varDispatch + varByRef,
      varUnknown,
      varUnknown + varByRef,
      varAny:begin
        if Source^.VPointer=nil then raise EVariantDispatchError.Create('Cannot invoke nil.'+AName);
        VarDispProc(@Result, PVariant(Source)^, @cd[1],pointer(p));
      end;
    else
      if FindCustomVariantType(Source^.VType,Custom) then
        TFakeCustomVariantType(Custom).DispInvoke(@Result, Source^, @cd[1],pointer(p))
      else
        VarInvalidOp;
    end;
  end;
end;

procedure FreeVariantInvoker(const AObj:TObject);
begin
  if(AObj<>nil)and(AObj is TVariantInvoker)then
    AObj.Free;
end;

function VarIsInvokeable(const V:variant):boolean;
var P:PVarData;
    Custom:TCustomVariantType;
begin
  result:=false;

  P:=@v;

  case P^.VType of
    varDispatch,
    varDispatch + varByRef,
    varUnknown,
    varUnknown + varByRef,
    varAny:
      result:=true;
  else
    if FindCustomVariantType(TVarData(P^).VType,Custom) then
      result:=Custom is TInvokeableVariantType;
  end;
end;

function VarIsObjectOrInvokeable(const V:variant):boolean;
begin
  result:=VarIsObject(V) or VarIsInvokeable(V);
end;

function VarAsObjectOrInvoker(const V:variant):TObject;
var vt:TCustomVariantType;
begin
  if varIsObject(V) then result:=VarAsObject(v)
  else if VarIsInvokeable(V) then result:=TVariantInvoker.Create(V)
  else if VarIsArray(V) then result:=TVariantInvoker.Create(VReference(PVariant(@V)^)) {!!!!!!!!!!!!!!!!!}
  else if FindCustomVariantType(TVarData(V).VType,vt)and vt.InheritsFrom(TCustomVariantTypeSpecialRelation)then
    result:=TCustomVariantTypeSpecialRelation(vt).AsObject(TVarData(V))
  else raise EVariantTypeCastError.Create('Cannot cast '+VarTypeAsText(VarType(V))+' to TObject or TVariantInvoker');
end;


// -----------------------------------------------------------------------------
// basic parser functions                                                     //
// -----------------------------------------------------------------------------

function ParseSkipWhiteSpace(var ch:PAnsiChar):boolean;
begin
  if ch^ in[#10,#13,#9,' ']then begin
    result:=true;
    while ch^ in[#10,#13,#9,' ']do inc(ch);
  end else result:=false;
end;

function ParseSkipPascalComment(var ch:PAnsiChar;const inAsm:boolean):boolean;
begin
  result:=true;
  if ch^='{' then begin
    repeat
      inc(ch);
      if ch^=#0 then exit;
    until(ch^='}');
    inc(ch);
  end else if(ch[0]='/')and(ch[1]='/') or inAsm and(ch[0]=';') then begin
    inc(ch);
    repeat
      inc(ch);
    until ch^ in[#0,#10,#13];
  end else if(ch[0]='(')and(ch[1]='*') then begin
    inc(ch,2);
    while ch^<>#0 do begin
      if ch^='*'then begin
        inc(ch);
        if ch^=')' then begin
          inc(ch);
          exit;
        end;
      end else
        inc(ch);
    end;
  end else if(ch[0]='/')and(ch[1]='*') then begin
    inc(ch,2);
    while ch^<>#0 do begin
      if ch^='*'then begin
        inc(ch);
        if ch^='/' then begin
          inc(ch);
          exit;
        end;
      end else
        inc(ch);
    end;
  end else
    result:=false;
end;

function ParsePascalDirective(var ch:PAnsiChar):ansistring;
var ch0:pansichar;
begin
  ch0:=pointer(ch);
  while not(ch^in [#0,'}'])do inc(ch);
  setlength(result,integer(ch)-integer(ch0)-2);
  move(ch0[2],result[1],length(result));
  if ch^<>#0 then inc(ch);
end;

procedure ParseSkipPascalDirective(var ch:PAnsiChar);
begin
  while not(ch^in [#0,'}'])do inc(ch);
  if ch^<>#0 then inc(ch);
end;

function ParseIdentifier(var ch:PAnsiChar;out Res:ansistring):boolean;
var st:PAnsiChar;
begin
  Res:='';
  result:=ch^ in ['a'..'z','A'..'Z','_',#128..#255];
  if result then begin
    st:=ch;
    repeat
      inc(ch);
    until not(ch^ in ['a'..'z','A'..'Z','_',#128..#255,'0'..'9']);
    setlength(res,cardinal(ch)-cardinal(st));
    move(st^,res[1],length(res));
  end;
end;

function ParseSign(var ch:PAnsiChar):integer;//-1 if fail
begin
  if ch^='+' then result:=1 else
  if ch^='-' then result:=-1 else result:=0;
  if result<>0 then inc(ch);
end;

function ParseDigit(var ch:pansichar;const base:integer):integer;//-1 if fail
asm
  mov ecx,[eax]
  movzx ecx,byte ptr[ecx]
  cmp edx,10; je @@dec
  cmp edx,16; je @@hex
  cmp edx, 2; je @@bin
@@err:
    mov eax,-1
    ret
@@dec:
  sub ecx,'0'
  cmp ecx,9;  ja @@err
  inc [eax]; mov eax,ecx
  ret
@@hex:
  sub ecx,'0'
  cmp ecx,9; ja @@letterBig
  inc [eax]; mov eax,ecx
  ret
@@letterBig:
  sub ecx,11h
  cmp ecx,5; ja @@letterSmall
  inc [eax]; lea eax,[ecx+10]
  ret
@@letterSmall:
  sub ecx,20h
  cmp ecx,5; ja @@err
  inc [eax]; lea eax,[ecx+10]
  ret
@@bin:
  sub ecx,'0'
  cmp ecx,1
  ja @@err
  inc [eax]; mov eax,ecx
  ret
end;

function ParseBase(var ch:PAnsiChar):integer;
begin
  if ch[0]='0' then case ch[1] of
    'b','B':begin result:= 2;inc(ch,2)end;
    'o','O':begin result:= 8;inc(ch,2)end;
//    'd','D':begin result:=10;inc(ch,2)end;
    'x','X':begin result:=16;inc(ch,2)end;
    else result:=10;
  end else if ch^='$' then begin result:=16;inc(ch);end
  else result:=0;
end;

procedure RaiseParserError(const s:string);
begin
  raise EParserError.Create(s);
end;

procedure ParseNumber64(var ch:PAnsiChar;out res:int64;const base:integer);
var num:integer;
    i:integer;
begin
  //elso szamjegy (kotelezo)
  num:=ParseDigit(ch,base);
  if(num<0)then RaiseParserError('Invalid character in numeric constant');

  //32bitesek
  while cardinal(num)<$0fFFffFF do begin
    i:=ParseDigit(ch,base);
    if i<0 then begin res:=cardinal(num);exit;end;//result
    num:=cardinal(num)*cardinal(base)+cardinal(i);
  end;

  //innentol 64bit
  res:=cardinal(num);
  while true do begin
    i:=ParseDigit(ch,base);
    if(i<0)then exit;//result
    res:=res*base+i;
  end;
end;

function ParseNumber64Dec(const ch:PAnsiChar;out res:int64):PAnsiChar;
var num:integer;
    i:integer;
begin
  result:=ch;
  num:=ord(result^)-ord('0');
  if cardinal(num)>9 then RaiseParserError('Invalid number');
  inc(result);

  //32bitesek
  while cardinal(num)<$0fFFffFF do begin
    i:=ord(result^)-ord('0');
    if cardinal(i)>9 then begin
      res:=num;
      exit;
    end;
    inc(result);
    num:=cardinal(num)*10+cardinal(i);
  end;

  //innentol 64bit
  res:=cardinal(num);
  while true do begin
    i:=ord(result^)-ord('0');
    if cardinal(i)>9 then begin
      exit;
    end;
    inc(result);
    res:=res*10+i;
  end;
end;

procedure ParseNumber32(var ch:PAnsiChar;out res:integer;const base:integer=10);
var i:integer;
begin
  //elso szamjegy (kotelezo)
  res:=ParseDigit(ch,base);
  if(res<0)then RaiseParserError('Invalid number');

  while true do begin
    i:=ParseDigit(ch,base);
    if(i<0)then exit;
    res:=res*base+i;
  end;
end;

function ParsePascalStringConstant(var ch:PAnsiChar;out res:ansistring):boolean;
var p0:pansichar;

  procedure flush;
  var i,j:integer;
  begin
    i:=cardinal(ch)-cardinal(p0);
    if i>0 then begin
      j:=length(res);
      setlength(res,j+i);
      move(p0^,res[j+1],i);
    end;
  end;

var st:pansichar;
    quot:ansichar;
    base,num,i,j:integer;
begin
  result:=false;
  res:='';
  st:=ch;
  while ch^ in ['''','"','#'] do begin
    if ch^='#' then begin
      inc(ch);
      base:=ParseBase(ch);if base=0 then base:=10;
      if base=16 then begin
        //1st hex digit
        i:=ParseDigit(ch,16);  if i<0 then exit(false);
        //2nd hex digit, if present
        j:=ParseDigit(ch,16);  if j>=0 then i:=i shl 4+j;
        result:=true;
        res:=res+ansichar(i);
        if j>=0{2digits already}then while true do begin
          i:=ParseDigit(ch,16);
          if i<0 then break;
          i:=i shl 4+ParseDigit(ch,16);
          if i<0 then exit(false);
          res:=res+ansichar(i);
        end;
      end else begin
        ParseNumber32(ch,num,base);
        res:=res+ansichar(num);
      end;
    end else begin
      quot:=ch^;
      inc(ch);p0:=ch;
      while true do
        if ch^=quot then begin
          flush;
          inc(ch);p0:=ch;
          if ch^=quot then begin//double quot
            flush;
            inc(ch);
          end else begin//string vege
            result:=true;
            break;
          end;
        end else begin
          if ch^=#0 then exit(false);//unterminated
          inc(ch);
        end;
    end;
    st:=ch;ParseSkipWhiteSpace(ch);
  end;

  ch:=st;
end;

function MyEncodeDate(Year, Month, Day: integer):TDateTime;
  const MyMonthDays: array [Boolean,0..11]of integer=
    ((0, 31, 59, 90, 120,151,181,212,243,273,304,334{,365}),
     (0, 31, 60, 91, 121,152,182,213,244,274,305,335{,366}));
var i,d:Integer;
begin
  if year<=50 then year:=year+2000 else
  if year<=100 then year:=year+1900;

  dec(Month);
  if Month>=12 then begin
    d:=Month div 12;
    Year:=Year+d;
    Month:=Month-d*12;
  end else if Month<0 then begin
    d:=-Month div 12+1;
    Year:=Year-d;
    Month:=Month+d*12;
  end;

  Day:=Day+MyMonthDays[IsLeapYear(Year),Month];
  I:=Year-1;
  result:= I*365+I div 4-I div 100+I div 400+Day-DateDelta;
end;

function MyEncodeTime(const Hour,Min:integer;const sec:double):TDateTime;
begin
  result:=(1/24)*Hour+(1/24/60)*Min+(1/24/60/60)*sec;
end;

procedure ParseSignedNumber32(var ch:pansichar;out num:integer;const base:integer);
var sgn:integer;
begin
  sgn:=ParseSign(ch);
  ParseNumber32(ch,num,base);
  if sgn<0 then num:=-num;
end;

function ParsePascalConstant(var ch:PAnsiChar):variant;//unassigned, ha error
var base:integer;
    p0:PAnsiChar;
    s:ansistring;
    num,frac:int64;
    exp,fracexp:integer;

    extVal:extended;
    DateTimeVal:TDateTime;
    min,sec,thousands:integer;

  procedure NumToResult;
  begin
    if(num>=low(integer ))and(num<=high(integer ))then Result:=integer(num)else
    if(num>=low(cardinal))and(num<=high(cardinal))then Result:=integer(num)else
      result:=num;                                           //^^^^ ez amiatt int, mert $FFFFFFFF-et is igy tudja csak kezelni, nincs cardinal variant !!!!!
  end;

var neg:boolean;
label start;
begin
  neg:=false;
  base:=10;
start:
  case ch^ of
    '1'..'9':begin
      ch:=ParseNumber64Dec(ch,num);
    end;
    '0':begin
      inc(ch);
      case ch^ of
        '0'..'9':begin ch:=ParseNumber64Dec(ch,num);end;
//        'd','D':begin inc(ch);ch:=ParseNumber64Dec(ch,num);end;
        'x','X':begin base:=16;inc(ch);ParseNumber64(ch,num,base);end;
        'b','B':begin base:=2;inc(ch);ParseNumber64(ch,num,base);end;
        else begin num:=0 end;
      end;
    end;
    '$':begin base:=16;inc(ch);ParseNumber64(ch,num,base);end;
    '-':begin inc(ch);neg:=not neg;goto start end;
    '+':begin inc(ch);goto start end;
    #9,#10,#13,' ':begin inc(ch);goto start end;
    '"','''','#':begin
        ParsePascalStringConstant(ch,s);
        if length(s)=1 then result:=s[1]
                       else result:=s;
        exit;
      end;
    else
      RaiseParserError('Invalid constant');
  end;

  //innentol num-ban van egy szam
  case ch^ of
    '.':begin //num.frac
      inc(ch);

      if not(ch^ in['0'..'9'])then begin
        NumToResult;
        dec(ch);
        exit;
      end;

      p0:=ch;
      ParseNumber64(ch,frac,base);
      fracexp:=cardinal(ch)-cardinal(p0);

      case ch^ of
        'e','E','g','G':begin //num.frac E exp
          inc(ch);
          ParseSignedNumber32(ch,exp,base);

          ExtVal:=Power(base,exp)*(num+Power(base,-fracExp)*frac);
          result:=ExtVal;
        end;
        '.':begin//YYYY.MM.DD
          inc(ch);

          if not(ch^ in['0'..'9'])then begin
            ExtVal:=num+Power(base,-fracExp)*frac;
            result:=ExtVal;
            dec(ch);
            exit;
          end;

          ParseNumber32(ch,exp,base);
          DateTimeVal:=MyEncodeDate(num,frac,exp);

          if(ch[0]=' ')and(ch[1] in['0'..'9'])then begin //YYYY.MM.DD HH:MM
            Result:=ParsePascalConstant(ch);
            if VarType(Result)=varDate then begin
              result:=result+DateTimeVal;
            end else
              RaiseParserError('Invalid date format');
          end else
            result:=DateTimeVal;
        end
        else begin //num.frac
          ExtVal:=num+Power(base,-fracExp)*frac;
          result:=ExtVal;
        end;
      end;
    end;
    'e','E','g','G':begin //num E exp
      inc(ch);
      ParseSignedNumber32(ch,exp,base);

      ExtVal:=Power(base,exp)*num;
      result:=ExtVal;
    end;
    ':':begin //HH:MM:SS.zzzzzz
      inc(ch);
      if not(ch^ in['0'..'9'])then begin
        // 3:= -t ugy vegye, hogy 3  :=    ,igy a colon-t bekenhagyja, ha nem szam jon utana, hanem pl :=
        NumToResult;
        dec(ch);//rollback colon
        exit
      end;

      ParseNumber32(ch,min,base);

      DateTimeVal:=0{DateTimeVal}+(1/24)*num+(1/24/60)*min;

      if ch^=':'then begin //HH:MM:SS
        inc(ch);
        ParseNumber32(ch,sec,base);

        DateTimeVal:=DateTimeVal+(1/24/60/60)*sec;

        if ch^='.' then begin //HH:MM:SS.ZZZZZ
          inc(ch);
          if not(ch^ in['0'..'9'])then begin
            Result:=DateTimeVal;
            dec(ch);
            exit;
          end;

          p0:=ch;
          ParseNumber32(ch,thousands,base);
          fracexp:=cardinal(ch)-cardinal(p0);

          DateTimeVal:=DateTimeVal+(1/24/60/60)*Power(base,-fracExp)*thousands;
        end;
      end;

      Result:=DateTimeVal;
    end
    else begin //num
      NumToResult;
    end;
  end;

  if neg then result:=-result;
end;

function ParsePascalConstant(const s:ansistring):variant;
var ch:PAnsiChar;
begin
  if s='' then exit(unassigned);
  ch:=pointer(s);
  Result:=ParsePascalConstant(ch);
end;

//ch-tol visszateker addig, ahol nincs comment/string.
//Onnan lehet kezdeni a lassabb parseolast
procedure ParsePascalRewindCommentsAndStrings(const chFirst:PAnsiChar;var ch:PAnsiChar;out AsmMode:TAsmMode;const InitialAsmMode:TAsmMode=asmNone);
var chMax:PAnsiChar;

  function skipUntil(const StopChar:AnsiChar):boolean;
  var act:PAnsiChar;
  begin
    act:=ch;
    inc(act);
    while true do begin
      if act^=#0 then exit(false) else
      if act^=StopChar then begin
        inc(act);
        result:=cardinal(act)<=cardinal(chMax);
        if result then ch:=act;
        exit;
      end;
      inc(act);
    end;
  end;

  function skipUntilNewLine:boolean;
  var act:PAnsiChar;
  begin
    act:=ch;
    while true do begin
      if act^=#0 then exit(false) else
      if act^ in[#10,#13]then begin
        //inc(act);//ide nem kell
        result:=cardinal(act)<=cardinal(chMax);
        if result then ch:=act;
        exit;
      end;
      inc(act);
    end;
  end;

  function skipUntil2(const w:word):boolean;
  var act:PAnsiChar;
  begin
    act:=ch;
    inc(act,2);
    while true do begin
      if act^=#0 then exit(false) else
      if PWord(act)^=w then begin
        inc(act,2);
        result:=cardinal(act)<=cardinal(chMax);
        if result then ch:=act;
        exit;
      end;
      inc(act);
    end;
  end;

const
  cPerPer=$2f2f;     // '//'
  cMulBracket=$292a; // '*)'
  cBracketMul=$2a28; // '(*'
  cPerMul=$2f29;
  cMulPer=$292f;

  wordSet=['a'..'z','A'..'Z','0'..'9','_'];

var inAsmBracketCnt:integer;
    s:ansistring;
    i:integer;
begin
  AsmMode:=InitialAsmMode;inAsmBracketCnt:=0;
  if(chFirst=nil)or(ch=nil)or(cardinal(ch)<=cardinal(chFirst))then exit;
  chMax:=ch;
  ch:=chFirst;
  while(cardinal(ch)<cardinal(chMax))do case ch^ of
    '{':if not skipUntil('}')then exit;
    '''','"':if not skipUntil(ch^)then exit;
    'a','A','(',')','/',';':begin
      case PWord(ch)^ of
        cPerPer:if not skipUntilNewLine then exit;
        cPerMul:if not skipUntil2(cMulPer)then exit;
        cBracketMul:if not skipUntil2(cMulBracket)then exit;
      else
        case ch^ of
          'a','A':if(ch[1]in['s','S'])and(ch[2]in['m','M'])and(ch[3]='_')
                  and((integer(ch)=integer(chFirst))or not(ch[-1]in wordSet))then begin
            //get asm_word
            s:='';for i:=4 to 10 do if ch[i]in wordSet then s:=s+ch[i]else break;

            if cmp(s,'il' )=0 then AsmMode:=asmIL  else
            if cmp(s,'isa')=0 then AsmMode:=asmISA;

            if AsmMode<>asmNone then begin
              if not skipUntil('(')then exit;
              inAsmBracketCnt:=1;
            end;
          end;
          ';':if AsmMode<>asmNone then if not skipUntilNewLine then exit;
          '(':if AsmMode<>asmNone then inc(inAsmBracketCnt);
          ')':if AsmMode<>asmNone then begin dec(inAsmBracketCnt);if inAsmBracketCnt<=0 then AsmMode:=asmNone;end;
        end;
        inc(ch);
      end;
    end
  else
    inc(ch);
  end;
end;

function ParseAsmModeAt(const ACode:ansistring;const APos:integer):TAsmMode;
var ch:PAnsiChar;
begin
  result:=asmNone;
  if ACode='' then exit;
  ch:=psucc(pointer(ACode),Ensurerange(APos-1+1,0,length(ACode)));
  ParsePascalRewindCommentsAndStrings(pointer(ACode),ch,result);
end;

// -----------------------------------------------------------------------------
// Tokenizer                                                                  //
// -----------------------------------------------------------------------------

type
  TKeywordTableRec=record
    hash:integer;
    token:TToken;
    name:ansistring;
  end;
  TTokenSymbolTableRec=record
    Token:TToken;
    Secondary:array of record
      Token:TToken;
      Chr:ansichar;
    end;
  end;

var
  TokenSymbolTable:array[ansichar]of TTokenSymbolTableRec;
  KeywordTable:THetArray<TKeywordTableRec>;
  TokenClassTable:array[TToken]of TNodeBaseClass;


procedure PrepareTokenSymbolTable;
type ansiCharSet=set of ansichar;

  procedure a(const s:ansistring;const AToken:TToken);overload;
  begin
    if length(s)>0 then with TokenSymbolTable[s[1]]do begin
      if length(s)=1 then Token:=AToken;
      if length(s)=2 then begin
        setlength(Secondary,length(Secondary)+1);
        with Secondary[high(Secondary)]do begin
          Token:=AToken;
          Chr:=s[2];
        end;
      end;
    end;
  end;

  procedure a(const s:ansicharset;const AToken:TToken);overload;
  var ch:ansichar;
  begin
    for ch in s do a(ch,AToken);
  end;

begin
  a('+',tkPlus);  a('-',tkMinus);
  a('*',tkMul);  a('/',tkDiv);
  a('%',tkMod);
  a('&',tkConcat);

{$IFDEF POWER}
  a('^',tkPower);
{$ELSE}
  a('^',tkIndirect);
  a('**',tkPower);
{$ENDIF}
  a('@',tkReference);

  a(':=',tkLet);  a('+=',tkLetAdd);  a('-=',tkLetSub);  a('*=',tkLetMul);
  a('/=',tkLetDiv);  a('%=',tkLetMod);  {a('^=',tkLetPower);}  a('&=',tkLetConcat);
  a('=>',tkLambda);

  a('++',tkInc);
  a('--',tkDec);

  a('<<',tkShl);  a('>>',tkShr);

  a('=',tkEqual);  a('<',tkLess);  a('>',tkGreater);  a('<=',tkLessEqual);
  a('>=',tkGreaterEqual);  a('<>',tkNotEqual);

  a('??',tkNullCoalescing);  a('!!',tkZeroCoalescing);
  a(':',tkColon);
  a(';',tkSemiColon);
  a(',',tkComma);
  a('.',tkPoint);
  a('..',tkPointPoint);
  a('?',tkQuestion);
  a('!',tkFactorial);

  a('(',tkBracketOpen);  a(')',tkBracketClose);
  a('[',tkSqrBracketOpen);  a(']',tkSqrBracketClose);
  a('<?',tkSpecialBracketOpen);  a('?>',tkSpecialBracketClose);

  a(['0'..'9','$','#','''','"'],tkConstant);  //# is separated to const and directive
  a([#9,#10,#13,' '],tkWhiteSpace);
  a('(*',tkComment);
  a('/*',tkComment);
  a('//',tkComment);
  a('{',tkComment);
  a('{$',tkDirective);
  a(['a'..'z','A'..'Z','_'],tkIdentifier);
  a(#0,tkEof);

  a('![',tkAsm_InlinePas);
  a('\',tkBackSlash);
  a('@',tkAt);

  a('##',tkDoubleHashmark);
  a('{#',tkDirective);
end;

procedure PrepareKeywordTable;
  procedure a(const s:ansistring;const AToken:TToken);
  var k:TKeywordTableRec;
  begin
    k.name:=s;
    k.hash:=Crc32UC(s);
    k.token:=AToken;
    KeywordTable.InsertBinary(k,function(const a:TKeywordTableRec):integer begin result:=cmp(k.hash,a.hash)end,false);
  end;
begin
  a('And',tkAnd);
  a('Not',tkNot);
  a('Or',tkOr);
  a('Xor',tkXor);
  a('Div',tkIDiv);
  a('Mod',tkIMod);
  a('In',tkIn);
  a('Shl',tkShl);
  a('Shr',tkShr);
  a('Sal',tkSal);
  a('Sar',tkSar);
  a('Like',tkLike);
  a('Is',tkIs);

  a('Require',tkRequire); //Oxygene
  a('Begin',tkBegin);
  a('Ensure',tkEnsure);   //Oxygene
  a('End',tkEnd);
  a('If',tkIf);
  a('Then',tkThen);
  a('Else',tkElse);
  a('For',tkFor);
  a('To',tkTo);
  a('Downto',tkDownto);
  a('Towards',tkTowards);
  a('Step',tkStep);
  a('Where',tkWhere);
  a('Do',tkDo);
  a('Descending',tkDescending);
  a('While',tkWhile);
  a('Repeat',tkRepeat);
  a('Until',tkUntil);
  a('Unless',tkUnless);
  a('Case',tkCase);
  a('Of',tkOf);
  a('With',tkWith);
  a('Using',tkUsing);

  a('Procedure',tkProcedure);
  a('Function',tkFunction);
  a('Constructor',tkConstructor);
  a('Destructor',tkDestructor);
  a('Var',tkVar);
  a('Const',tkConst);
  a('Out',tkOut);
  a('Raise',tkRaise);

  //custom assemblers
  a('asm_il',tkAsm_il);
  a('asm_isa',tkAsm_isa);

  KeywordTable.Compact;
end;

procedure PrepareTokenClassTable;
  procedure a(const t:TToken;const c:TNodeBaseClass);
  begin TokenClassTable[t]:=c;end;
begin
  a(tkConstant,TNodeConstant);

  a(tkPlus,TNodePlus);
  a(tkMinus,TNodeMinus);
  a(tkNot,TNodeNot);
  a(tkFactorial,TNodeFactorial);
  a(tkInc,TNodeInc);a(tkDec,TNodeDec);
  a(tkPostInc,TNodePostInc);a(tkPostDec,TNodePostDec);
  a(tkIndirect,TNodeIndirect);a(tkReference,TNodeReference);


  a(tkNullCoalescing,TNodeNullCoalescing);
  a(tkZeroCoalescing,TNodeZeroCoalescing);
  a(tkIs,TNodeIs);
  a(tkPower,TNodePower);
  a(tkMul,TNodeMul);
  a(tkDiv,TNodeDiv);
  a(tkIDiv,TNodeIDiv);
  a(tkMod,TNodeMod);
  a(tkIMod,TNodeIMod);
  a(tkAnd,TNodeAnd);
  a(tkShl,TNodeShl);
  a(tkShr,TNodeShr);
  a(tkSal,TNodeSal);
  a(tkSar,TNodeSar);
  a(tkAdd,TNodeAdd);
  a(tkSub,TNodeSub);
  a(tkOr,TNodeOr);
  a(tkXor,TNodeXor);
  a(tkConcat,TNodeConcat);
  a(tkLike,TNodeLike);a(tkNotLike,TNodeNotLike);
  a(tkIn,TNodeIn);a(tkNotIn,TNodeNotIn);
  a(tkEqual,TNodeEqual);
  a(tkNotEqual,TNodeNotEqual);
  a(tkGreater,TNodeGreater);
  a(tkGreaterEqual,TNodeGreaterEqual);
  a(tkLess,TNodeLess);
  a(tkLessEqual,TNodeLessEqual);

  a(tkQuestion,TNodeTenary);
  {tkColon -> takolassal}
  a(tkColonTenary,TNodeTenaryChoices);
  a(tkColonNamedVariant,TNodeNamedVariant);

  a(tkLet,TNodeLet);
  a(tkLetAdd,TNodeLetAdd);
  a(tkLetSub,TNodeLetSub);
  a(tkLetMul,TNodeLetMul);
  a(tkLetDiv,TNodeLetDiv);
  a(tkLetPower,TNodeLetPower);
  a(tkLetMod,TNodeLetMod);
  a(tkLetConcat,TNodeLetConcat);
  a(tkLambda,TNodeLambda);
  a(tkRaise,TNodeRaise);

//  a(tkPoint,TNode_Field);
  a(tk_Field,TNode_Field);

  a(tk_Funct,TNode_Funct);
  a(tk_Index,TNode_Index);

  a(tkAsm_IL,TNodeInlineAsm);
  a(tkAsm_ISA,TNodeInlineAsm);
end;

function KeywordTokenByHash(const hash:integer):TToken;
var i:integer;
begin
  if KeywordTable.FindBinary(function(const a:TKeywordTableRec):integer begin result:=cmp(hash,a.hash)end,i)then result:=KeywordTable.FItems[i].token
  else result:=tkNone;
end;

function peekToken(var ch:PAnsiChar):TToken;
var nch:AnsiChar;i:integer;
begin
  with TokenSymbolTable[ch^]do begin
    result:=Token;
    if ch^<>#0 then begin
      nch:=pansichar(cardinal(ch)+1)^;
      for i:=0 to high(Secondary)do with Secondary[i]do if nch=Chr then
        exit(Token);
    end;
  end;
end;

function ParseSkipWhitespaceAndComments(var ch:PAnsiChar;const inAsm:boolean=false):boolean;
begin
  result:=false;
  while true do
    case peekToken(ch) of
      tkComment:begin result:=true;ParseSkipPascalComment(ch,inAsm);end;
      tkWhiteSpace:begin result:=true;ParseSkipWhiteSpace(ch);end;
    else
      break;
    end;
end;

function ParsePascalToken(var ch:PAnsiChar;out value:Variant):TToken;
var i,symlen:integer;
    nch:ansichar;
    s:ansistring;
begin
  value:=Unassigned;
  while true do with TokenSymbolTable[ch^]do begin
    symlen:=1;
    result:=Token;
    if ch^<>#0 then begin
      nch:=pansichar(cardinal(ch)+1)^;
      for i:=0 to high(Secondary)do with Secondary[i]do if nch=Chr then begin
        symlen:=2;result:=Token;break;
      end;
    end;
    case result of
      tkWhiteSpace:ParseSkipWhiteSpace(ch);
      tkComment:ParseSkipPascalComment(ch,false);
      tkIdentifier:begin
        ParseIdentifier(ch,s);
        Value:=s;
        result:=KeywordTokenByHash(Crc32UC(s));
        if result=tkNone then result:=tkIdentifier;
        exit;
      end;
      tkConstant:begin
        if(ch[0]='#')and(ch[1]in['a'..'z','A'..'Z','_'])then begin // #directive?
          inc(ch);
          ParseIdentifier(ch,s);
          result:=tkDirective;
          Value:='#'+s;
          exit;
        end;
        Value:=ParsePascalConstant(ch);
        if VarIsEmpty(Value)then
          result:=tkNone;//errort kellene kuldeni
        exit;
      end;
      tkDirective:begin value:=ParsePascalDirective(ch);exit end;
      tkNone,tkEof:exit;
    else
      inc(ch,symlen);exit;
    end;
  end;
end;

type
  TInlineAsmState=record
    AsmMode:TAsmMode;
    inlinePas:boolean;
    AsmBracketCnt,
    AsmSqrBracketCnt:integer;
    AsmLabel:boolean;{@ jel volt, jonni fog a egy identifier}
  end;

function ParsePascalSyntax(var ch:PAnsiChar;var inlineAsmState:TInlineAsmState;var lastT:TToken):TSyntaxKind;
var i,symlen,h:integer;
    nch:ansichar;
    s:ansistring;
    t:ttoken;
    lastWasPoint:boolean;
    labelWillCome:boolean;
begin
  result:=skSymbol;
  labelWillCome:=false;
  while true do with TokenSymbolTable[ch^], InlineAsmState do begin
    symlen:=1;
    //get token
    lastWasPoint:=lastt=tkPoint;//na itt van kavarodas, a lenyeg, hogy a .swizzle checknek tudnia kell, hogy '.' utan van az identifier vagy nem
    t:=Token;lastT:=t;
    if ch^<>#0 then begin
      nch:=pansichar(cardinal(ch)+1)^;
      for i:=0 to high(Secondary)do with Secondary[i]do if nch=Chr then begin
        symlen:=2;t:=Token;break;
      end;
    end;

    //refine token
    if(AsmMode<>asmNone)then begin
      if(t=tkSemiColon)then
        t:=tkComment;//asm comment
      if(t=tkAt)then begin
        labelWillCome:=true;
        inc(ch);Continue;
      end;
    end;

    case t of
      tkWhiteSpace:begin
        ParseSkipWhiteSpace(ch);
        exit(skWhitespace);
      end;
      tkDirective:begin
        ParseSkipPascalDirective(ch);
        exit(skDirective);
      end;
      tkComment:begin
        ParseSkipPascalComment(ch,AsmMode<>asmNone);
        exit(skComment);
      end;
      tkIdentifier:begin
        ParseIdentifier(ch,s);
        h:=Crc32UC(s);
        t:=KeywordTokenByHash(h);

        if(AsmMode=asmNone)or inlinepas then begin
          if t=tkNone then begin
            result:=skIdentifier1;
          end else begin
            result:=skKeyword;
            case t of
              tkAsm_IL :begin AsmMode:=asmIL ;AsmBracketCnt:=0;end;
              tkAsm_ISA:begin AsmMode:=asmISA;AsmBracketCnt:=0;end;
            end;
          end;
        end else begin //asm
          //labels
          if labelWillCome then begin
            result:=skLabel;
          end else case asmMode of                    //asm highlight identifier
            asmIL:  result:=_Asm_il_syntax(switch(lastWasPoint,'.')+s);
            asmISA: result:=_Asm_isa_syntax(s);
          end;
        end;
        exit;
      end;
      tkConstant:begin
        if(ch[0]='#')and(ch[1]in['a'..'z','A'..'Z','_'])then begin // #directive?
          inc(ch);
          ParseIdentifier(ch,s);
          exit(skDirective);
        end;

        if not inlinePas and(AsmMode=asmIL)and(lastWasPoint)and(ch^in['0'..'9'])then begin//amd_il swizzle
          s:='.';while ch^ in['0'..'9','a'..'z','A'..'Z','_']do begin s:=s+ch^;inc(ch);end;
          exit(_Asm_il_syntax(s));
        end;

        if ch^ in ['"','''','#']then result:=skString
                                else result:=skNumber;
        try
          if VarIsEmpty(ParsePascalConstant(ch))then result:=skError
        except
          result:=skError;
        end;
        exit;
      end;
      tkNone:begin inc(ch);exit(skError) end;
      tkEof:exit;
    else //symbol
      if AsmMode<>asmNone then case t of   //asm leave
        tkBracketOpen:inc(AsmBracketCnt);
        tkBracketClose:begin dec(AsmBracketCnt);if AsmBracketCnt=0 then AsmMode:=asmNone end;
        tkAsm_inlinePas:begin inlinepas:=true;AsmSqrBracketCnt:=1;end;
        tkSqrBracketOpen:inc(AsmSqrBracketCnt);
        tkSqrBracketClose:begin dec(AsmSqrBracketCnt);if AsmSqrBracketCnt=0 then inlinePas:=false end;
      end;
      inc(ch,symlen);
      exit;
    end;
  end;
end;

procedure ParseHighlightPascalSyntax(const ASrc:ansistring;var ADst:ansistring;const AFrom:integer=1;const ATo:integer=$7fffffff{1based};const InitialAsmMode:TAsmMode=asmNone);
var st,en:integer;
    chFirst,chPrev,chEnd,syFirst,ch:PAnsiChar;
    sk:TSyntaxKind;
    inlineAsmState:TInlineAsmState;
    lastT:TToken;
begin
  SetLength(ADst,length(ASrc));
  if ASrc='' then exit;
  st:=EnsureRange(AFrom-1,0,Length(ASrc)-1);
  en:=EnsureRange(ATo  -1,0,Length(ASrc)-1);
  if st>en then exit;
  //parse
  chFirst:=pointer(ASrc);
  ch:=@chFirst[st];
  chEnd:=@chFirst[en];
  syFirst:=pointer(ADst);
  //seek
  fillchar(inlineAsmState,sizeof(inlineAsmState),0);
  ParsePascalRewindCommentsAndStrings(chFirst,ch,inlineAsmState.AsmMode,InitialAsmMode);
  with inlineAsmState do asmBracketCnt:=switch(asmMode<>asmNone,1,0);//adjust first bracket(
  //parse
  lastT:=tkNone;
  while ch<=chEnd do begin
    chPrev:=ch;
    sk:=ParsePascalSyntax(ch,inlineAsmState,lastT);
    if ch=chPrev then inc(ch);//no deadloop
    FillChar(pointer(cardinal(syFirst)+cardinal(chPrev)-cardinal(chFirst))^,cardinal(ch)-cardinal(chPrev),ord(sk));
  end;
end;

function ParseCountChars(const ASrc:ansistring;const AChar:ansichar):integer;
var i:integer;
begin
  result:=0;
  for i:=1 to length(ASrc)do if ASrc[i]=AChar then inc(result);
end;

function ParseCountChars(const AFrom,ATo:pansichar;const AChar:ansichar):integer;
var p:PAnsiChar;
begin
  result:=0;
  if(AFrom=nil)then exit;
  p:=AFrom;
  while cardinal(p)<cardinal(ATo)do begin
    if p[0]=AChar then inc(result);
    inc(p);
  end;
end;

function ParseRealignLines(const ASrc:ansistring;const AMaxColumns,AFirstLineColumns,ATargetLineCount:integer):ansistring;
var ch,ch0:pansichar;
    lastChar:ansichar;
    tk:TToken;
    val:variant;
    needSpace:boolean;
    ActColumn,LineCount:integer;
begin
  result:='';
  ch:=pointer(ASrc);
  lastChar:=#0;
  ActColumn:=AFirstLineColumns;
  LineCount:=1;
  with AnsiStringBuilder(result)do begin
    if ch<>nil then while true do begin
      needspace:=ParseSkipWhitespaceAndComments(ch);
      ch0:=ch;
      try tk:=ParsePascalToken(ch,val);except tk:=tkIdentifier;inc(ch)end;
      if tk=tkNone then begin tk:=tkIdentifier;inc(ch)end;

      if tk=tkEof then break;
      needSpace:=needspace or((lastChar in['a'..'z','A'..'Z','0'..'9','_',']'])   //']' <- gányolás, hogy a GCN ASM ne rakja ossze az optionokat
                              and(ch0[0]   in['a'..'z','A'..'Z','0'..'9','_']));
      if(ActColumn+ord(needSpace)+integer(ch)-integer(ch0)>AMaxColumns)and(ActColumn>0)then begin
        AddStr(#13#10);needSpace:=false;inc(LineCount);
        ActColumn:=0;
      end;
      if needspace then begin AddChar(' ');inc(ActColumn);end;
      AddBlock(ch0^,integer(ch-ch0));inc(ActColumn,integer(ch-ch0));
      lastChar:=ch[-1];
    end;
    while(LineCount<ATargetLineCount)do begin
      AddStr(#13#10);inc(LineCount);
    end;
  end;
end;

// -----------------------------------------------------------------------------
// Node                                                                       //
// -----------------------------------------------------------------------------

function TNodeManyOp.AddSubnode(const n:tnodeBase):TNodeBase;
begin
  result:=n;
  FSubNodes.Append(n);
end;

function TNodeManyOp.Dump(const AIndent:integer=0):ansistring;
var i:integer;
begin
  result:=Indent('   ',AIndent)+ ansistring(ClassName)+' '+#13#10;
  for i:=0 to FSubNodes.FCount-1 do begin
    if FSubNodes.FItems[i]=nil then
      result:=result+Indent('   ',AIndent+1)+'nil'+#13#10
    else
      result:=result+FSubNodes.FItems[i].Dump(AIndent+1);
  end;
end;

procedure TNodeManyOp.SetSubNode(const n: integer; const ANode: TNodeBase);
begin
  while n>=FSubNodes.FCount do AddSubNode(nil);
  FSubNodes.FItems[n]:=ANode;
end;

function TNodeManyOp.SubNode(const n: integer): TNodeBase;
begin
  if n<FSubNodes.FCount then result:=FSubNodes.FItems[n]
                        else result:=nil;
end;

function TNodeManyOp.SubNodeCount: integer;
begin
  result:=FSubNodes.FCount;
end;

// -----------------------------------------------------------------------------
// Compiler                                                                   //
// -----------------------------------------------------------------------------

type
  TCompiler=class
  private
    chStart:PAnsiChar;
    ch:pansichar;
    tk:TToken;
    val:Variant;

    saved:record
      ch:pansichar;
      tk:TToken;
      val:Variant;
    end;

    IgnoreColonInExpression:boolean;
    procedure Parse;
    function CreateOp(const AToken:TToken;const AOp1,AOp2:TNodeBase):TNodeBase;
  public
  type
    TCompileSequenceOption=(StopAfterFirstBlock,HandleEnsure{,HandleFinally});
    TCompileSequenceOptions=set of TCompileSequenceOption;
  var
    LocalNameSpace:TNameSpace;
    CurrentPosition:integer;
    Warnings:array of record Msg:ansistring;Position:integer end;

    procedure Warning(const AMsg:AnsiString);
    function NopIfNil(const n:TNodeBase):TNodeBase;
    function Expect(const tk1:TToken;const tk2:TToken=tkNone;const tk3:TToken=tkNone;const tk4:TToken=tkNone):TToken;

    procedure SaveState;
    procedure RestoreState;

    function CompileVariable:TNodeBase;
    function CompileInnerSetConstruct:TNodeSetConstruct;
    function CompileConstant:TNodeConstant;
    function CompileTag(const mustExists:boolean):TNodeBase;
    function CompileExpression_NoLocalNameSpace(const mustExists:boolean):TNodeBase;
    function CompileExpression(const mustExists:boolean;const VarCanContinueafterComma:boolean=false):TNodeBase;
    function CompileStatement:TNodeBase;
    procedure CompileProcedure(const OuterClassT:ansistring);//namespace-ba rakja
    function CompileSequence(const AClosingToken:TToken;const AOptions:TCompileSequenceOptions=[]):TNodeBase;
    function CompileAsm: TNodeInlineAsm;
  end;

procedure TCompiler.Parse;
begin
  tk:=ParsePascalToken(ch,val);
  CurrentPosition:=integer(ch)-integer(chStart);
end;

procedure TCompiler.RestoreState;
begin
  ch:=pointer(saved.ch);
  tk:=saved.tk;
  val:=saved.val;
end;

procedure TCompiler.SaveState;
begin
  saved.ch:=pointer(ch);
  saved.tk:=tk;
  saved.val:=val;
end;

function TCompiler.CreateOp(const AToken:TToken;const AOp1,AOp2:TNodeBase):TNodeBase;
var c:TNodeBaseClass;
begin
  c:=TokenClassTable[AToken];
  if c=nil then CompileError('Unknown operation token : '+ansistring(GetEnumName(TypeInfo(TToken),ord(AToken))));
  result:=c.Create;
  if AOp1<>nil then Result.SetSubNode(0,AOp1);
  if AOp2<>nil then Result.SetSubNode(1,AOp2);
end;

function TCompiler.Expect;

  function getName(const tk:TToken):ansistring;
  begin
    if tk=tkNone then result:=''
                 else result:=copy(GetEnumName(TypeInfo(TToken),Ord(tk)),3,$ff);
  end;

var s:ansistring;


  procedure AppendName(tk:TToken);
  var n:ansistring;
  begin
    n:=getName(tk);
    if n<>'' then ListAppend(s,n,' or ');
  end;

begin
  result:=tk;
  if(tk1=tk)or
    ((tk2<>tkNone)and(tk2=tk))or
    ((tk3<>tkNone)and(tk3=tk))or
    ((tk4<>tkNone)and(tk4=tk))then exit;

  AppendName(tk1);
  AppendName(tk2);
  AppendName(tk3);
  AppendName(tk4);
  s:=s+' expected but '+getName(tk)+' found';
  CompileError(s);
end;

function IdentifierName(const AOp:TNodeBase):ansistring;
begin
  if AOp=nil then ExecError('IdentifierName() Cannot get name from NIL') else
  if AOp is TNodeIdentifier then result:=TNodeIdentifier(AOp).FIdName else
  if AOp is TNodeConstant then result:=TNodeConstant(AOp).Value else
    ExecError('IdentifierName() Cannot get name from '+AOp.ClassName);
end;

function IsIdentifier(const AOp:TNodeBase):boolean;
begin
  result:=(AOp is TNodeIdentifier)or(AOp is TNodeConstant{COM ID});
end;

procedure TCompiler.Warning(const AMsg:AnsiString);
begin
  SetLength(Warnings,length(Warnings)+1);
  with Warnings[high(Warnings)]do begin
    Msg:=AMsg;
    Position:=CurrentPosition;
  end;
end;

function TCompiler.CompileVariable:TNodeBase;  // a.b[23,5].d(16)
var n:TNodeBase;
    plist:TNodeParamList;
label L1;
begin
  result:=nil;
  if tk<>tkIdentifier then exit;

  result:=TNodeIdentifier.Create(ansistring(Val));
  try

    parse;
  L1:
    case tk of
      tkPoint:begin
        parse;
        case tk of
          tkIdentifier:result:=CreateOp(tk_Field,Result,TNodeIdentifier.Create(ansistring(val)));
          tkConstant:if VarIsOrdinal(val)then result:=CreateOp(tk_Field,Result,TNodeIdentifier.Create(ansistring(val)))
                                         else CompileError('Identifier or DispID expected');
        else
          CompileError('Identifier or DispID expected');
        end;
        parse;
        goto L1;
      end;
      tkBracketOpen:begin // ( , , , )
        plist:=TNodeParamList.Create;
        Result:=CreateOp(tk_Funct,result,plist);
        Parse;
        while true do begin
          if tk=tkBracketClose then begin Parse;break end;//end of paramlist
          n:=CompileExpression(true);
          if n=nil then CompileError('Function parameter expected');
          plist.AddSubnode(n);
          case tk of
            tkComma:begin Parse;Continue;end;
            tkBracketClose:;
            else CompileError('"," or ")" expected in parameter list');
          end;
        end;
        goto L1;
      end;
      tkSqrBracketOpen:begin // [ , , , ]
        plist:=TNodeParamList.Create;
        Result:=CreateOp(tk_Index,result,plist);//ez is funct
        Parse;
        while true do begin
          if tk=tkSqrBracketClose then begin Parse;break end;//end of list
          n:=CompileExpression(true);
          if n=nil then CompileError('Index parameter expected');
          plist.AddSubnode(n);
          case tk of
            tkComma:begin Parse;Continue;end;
            tkSqrBracketClose:;
            else CompileError('"," or "]" expected in index parameter list');
          end;
        end;
        goto L1;
      end;
      tkIndirect:begin
        Result:=CreateOp(tkIndirect,result,nil);
        Parse;
        goto L1;
      end;
    end;

  except
    result.Free;raise
  end;
end;

function TCompiler.CompileConstant:TNodeConstant; // identifier, const
//Identifier, const
begin
  if tk=tkConstant then begin
    result:=TNodeConstant.Create(val);
    try
      parse
    except
      result.Free;raise;
    end;
  end else result:=nil;
end;

function TCompiler.CompileTag(const mustExists:boolean):TNodeBase;  //+-(+ not akarmi) ! {factorial}
var act:TNodeBase;

  procedure NodeAddLeaf(const n:TNodeBase);
  begin
    if result=nil then begin
      result:=n;
      act:=n;
    end else begin
      act.SetSubNode(0,n);
      act:=n;
    end;
  end;

var n,tmp1,tmp2:TNodeBase;
    r:TNodeRange;
    arr:TNodeArrayConstruct;
label L1;
begin
  result:=nil;
  n:=nil;
  try
    while tk in tkPreFixOperation do begin
      NodeAddLeaf(CreateOp(tk,nil,nil));
      Parse;
    end;

    //n <- parseolt nodetree
    case tk of
      tkSpecialBracketOpen:begin
        arr:=TNodeArrayConstruct.Create;
        n:=arr;
        Parse;
        while True do begin
          if tk=tkSpecialBracketClose then break;
          arr.AddSubNode(CompileExpression(true));
          if tk=tkEof then CompileError('Unclosed special array');
        end;
        parse;
      end;
      tkBracketOpen:begin
        Parse;
        n:=CompileExpression(false);
        if n=nil then begin//empty array
          n:=TNodeArrayConstruct.Create;
        end else
          if tk=tkComma then begin //array
            Parse;
            arr:=TNodeArrayConstruct.Create;arr.AddSubNode(n);n:=arr;
            while True do begin
              arr.AddSubNode(CompileExpression(true));
              if tk=tkComma then begin Parse;Continue;end
                            else break;
            end;
          end;
        if tk<>tkBracketClose then CompileError('")" expected');
        parse;
      end;
      tkSqrBracketOpen:begin//set constant
        Parse;
        n:=TNodeSetConstruct.Create;
        if tk=tkSqrBracketClose then begin
          parse
        end else while true do begin
          tmp1:=CompileExpression(true);
          if tk=tkPointPoint then begin
            Parse;
            tmp2:=CompileExpression(true);
            r:=TNodeRange.Create;
            r.FOp1:=tmp1;
            r.FOp2:=tmp2;
            TNodeSetConstruct(n).AddSubNode(r);
          end else begin
            TNodeSetConstruct(n).AddSubNode(tmp1);
          end;
          case tk of
            tkComma:begin parse;continue;end;
            tkSqrBracketClose:begin Parse;break end;
            else CompileError('"," or "]" expected in set constructor');
          end;
        end;
      end;
      else
        n:=CompileConstant;
        if n=nil then n:=CompileVariable;
        if(n=nil)and(tk in[tkAsm_IL,tkAsm_ISA])then n:=CompileAsm;
        if n=nil then begin
          if mustExists or(result<>nil) then
            CompileError('Constant or Variable expected');
        end;
    end;

    if n<>nil then while(tk in tkPostFixOperation) do begin
      if tk=tkInc then tk:=tkPostInc else
      if tk=tkDec then tk:=tkPostDec;

      NodeAddLeaf(CreateOp(tk,nil,nil));
      Parse;
    end;

    if n<>nil then NodeAddLeaf(n);
    n:=nil;
  except
    n.Free;result.Free;raise
  end;
end;

function TCompiler.CompileExpression_NoLocalNameSpace(const mustExists:boolean):TNodeBase;
var List:THetArray<TNodeBase>;
    OperationCount,OperandCount:integer;
    TenaryFound:boolean;

  function Operation(const n:integer):TNodeOp;
  begin result:=TNodeOp(List.FItems[n shl 1+1]);end;

  function Operand(const n:integer):TNodeBase;
  begin result:=List.FItems[n shl 1];end;

  procedure SolveOperation(n:integer);
  begin
    with Operation(n)do begin
      SetSubNode(0,Operand(n));
      SetSubNode(1,Operand(n+1))
    end;
    List.Remove(n shl 1);
    List.Remove(n shl 1+1);
    dec(OperandCount);
    dec(OperationCount);
  end;

{  function FindOperation(const st:integer;const tk1,tk2:TToken):integer;
  var i:integer;
  begin
    for i:=st to OperationCount-1 do if Operation(i).FToken=tk then exit(i);
    result:=-1;
  end;}


  function SolveRange(const st,en,prio:integer):integer;
    //Solves operations with priority equal or greater than the prio input param
    //st,en specifies the direction too
    //result will return with the maximum operand priority wich is less than the prio input param
    //result<0 means no more operands to process
    //result is obsolete on partial st..en ranges
  var i,j,p:integer;n:TNodeOp;
  begin
    result:=-1;
    if(st<0)or(en<0)then exit;//range check
    if st<=en then begin //left to right
      i:=st;j:=en;
      while i<=j do begin
        n:=Operation(i);
        p:=n.Priority;
        if p>=prio then begin
          SolveOperation(i);
          dec(j);
        end else begin
          if p>result then result:=p;
          inc(i);
        end;
      end;
    end else begin //right to left
      for i:=st downto en do begin
        n:=Operation(i);
        p:=n.Priority;
        if p>=prio then begin
          SolveOperation(i);
        end else begin
          if p>result then result:=p;
        end;
      end;
    end;
  end;

  procedure SolveSwitchesAndLets;
  //[a:=b:=c:=5?():()
  //? elott a legutolso muvelet a :=, es amugy rekurzivan.

  var i:integer;
      n:TNodeOp;
      qPos:integer;

  begin
    qPos:=-1;
    if TenaryFound then
      for i:=0 to OperationCount-1 do if Operation(i)is TNodeTenary then qPos:=i;
    if qPos<0 then begin
      SolveRange(OperationCount-1,0,3);//nincs ? ezert csak solve :=
    end else begin
      for i:=OperationCount-1 downto qPos+1 do begin// :=
        n:=Operation(i);
        if n.Priority=3 then SolveOperation(i);
      end;
      if qPos>=OperationCount-1 then CompileError('"?" found without ":"');
      if not(Operation(qPos+1)is TNodeTenaryChoices) then CompileError('"?" found without ":"');
      SolveOperation(qPos+1);
      SolveOperation(qPos);
      SolveSwitchesAndLets;
    end;
  end;

var prio:integer;
    qMarkCount,i:integer;
    lIgnoreColonInExpression:boolean;
begin
  lIgnoreColonInExpression:=IgnoreColonInExpression;IgnoreColonInExpression:=false;

  result:=CompileTag(mustExists);
  if Result=nil then exit;
  TenaryFound:=false;
  try
    qMarkCount:=0;

    if(tk=tkColon)and(not lIgnoreColonInExpression)then
      tk:=tkColonNamedVariant;

    if(TokenClassTable[tk]<>nil)and not(tk in[tkConstant,tkIdentifier]) {and(not tenary or(tk<>tkColon))}then begin
      //collect all operands, operations
      List.Append(result);
      repeat
        case tk of
          tkPlus:tk:=tkAdd;
          tkMinus:tk:=tkSub;
          tkNot:begin //not in, not like
            parse;
            if tk=tkIn then tk:=tkNotIn else
            if tk=tkLike then tk:=tkNotLike else
              CompileError('"In" or "Like" expected after "Not"');
          end;
          tkQuestion:begin TenaryFound:=true;inc(qMarkCount) end;//takolas a ?: es a case osszeakadasa miatt
          tkColon:if TenaryFound then tk:=tkColonTenary{
                                 else tk:=tkColonNamedVariant nincs, csak az elso muveletnel};
        end;

        List.Append(CreateOp(tk,nil,nil));
        parse;

        with List do if(tk=tkNot)and(FItems[FCount-1]is TNodeIs)then begin  // "not is"
          TNodeIs(FItems[FCount-1]).invert:=true;
          parse;
        end;

        List.Append(CompileTag(true));

        if tk=tkColon then
          if TenaryFound then tk:=tkColonTenary{
                         else tk:=tkColonNamedVariant};

        if tk=tkColonTenary then //takolas a ?: es a case osszeakadasa miatt
          if qMarkCount<=0 then break
                           else dec(qMarkCount);

      until TokenClassTable[tk]=nil;
      OperationCount:=List.FCount shr 1;
      OperandCount:=OperationCount+1;

      Prio:=SolveRange(OperationCount-1,0,255);//find max prio
      while Prio>=5 do
        Prio:=SolveRange(0,OperationCount-1,Prio);//std operations [5..9]

      SolveSwitchesAndLets;

      if List.FCount<>1 then CompileError('Error in expression (unable to process all operations)');
      result:=List.FItems[0];
    end;
  except
    for i:=0 to List.FCount-1 do List.FItems[i].Free;
    raise;
  end;
end;

//simple variant/const declarations, only 1 variable/tag
function TCompiler.CompileExpression(const mustExists:boolean;const VarCanContinueafterComma:boolean=false):TNodeBase;

  procedure Append(n:TNodeBase);
  var seq:TNodeSequence;
  begin
    if n=nil then
      exit
    else if result=nil then
      result:=n
    else if n is TNodeNop then begin
      n.Free;
      exit;
    end else if result is tnodenop then begin
      result.Free;
      result:=n;
    end else if result is TNodeSequence then begin
      TNodeSequence(result).AddSubNode(n);
    end else begin
      seq:=TNodeSequence.Create;
      seq.AddSubNode(result);
      seq.AddSubNode(n);
      result:=seq;
    end;
  end;

  procedure AddVar(const AName:ansistring);
  var nse:TNameSpaceEntry;
  begin
    nse:=LocalNameSpace.FindByName(AName);
    if nse=nil then begin
      LocalNameSpace.AddVariable(AName,Null);
    end else begin
      if nse is TNameSpaceVariable then begin
        Warning('Variable '+topas(LocalNameSpace.FName+'.'+AName)+' is redeclared');
      end else
        NameSpaceError(topas(LocalNameSpace.FName+'.'+AName)+' is allready defined and not a variable');
    end;
  end;

var ctx:TContext;
    tmp:TNodeBase;
    n:string;

begin
  result:=nil;
  try
    case tk of
      tkVar:begin
        repeat
          parse;
          tmp:=CompileExpression_NoLocalNameSpace(mustExists);
          if localNameSpace=nil then
            CompileError('Variant declaration not allowed (local namespace is nil)');
          if(tmp=nil)then
            CompileError('Identifier or Assignment expression needed after "Var"');
          try
            if (tmp is TNodeLet)and (TNodeLet(tmp).FOp1 is TNodeIdentifier) then begin
              AddVar(IdentifierName(TNodeLet(tmp).FOp1));
            end else if (tmp is TNodeIn)and (TNodeIn(tmp).FOp1 is TNodeIdentifier) then begin//for in
              AddVar(IdentifierName(TNodeIn(tmp).FOp1));
            end else if tmp is TNodeIdentifier then begin
              AddVar(IdentifierName(tmp));
              if VarCanContinueafterComma then
                freeandnil(tmp);
            end else
              CompileError('Identifier or Assignment expression needed after "Var"');
          except
            freeandnil(tmp);raise
          end;
          Append(tmp);

          //uz uberbrutal
          if VarCanContinueafterComma then case tk of
            tkComma:continue;
{            tkSemiColon:begin   //nem lehet, mert akkor nem lehet az utasitasok koze rakni
              SaveState;Parse;
              if tk=tkIdentifier then begin
                RestoreState;
                continue;
              end else
                RestoreState;
            end;}
          end;
          break;
        until false;
      end;
      tkConst:begin
        repeat
          parse;
          Result:=CompileExpression_NoLocalNameSpace(mustExists);
          if(result=nil)then
            CompileError('Expression needed after "Const"');
          if(result is TNodeLet)and(TNodeLet(result).FOp1 is TNodeIdentifier)then begin//named const
            if localNameSpace=nil then
              CompileError('Constant declaration not allowed (local namespace is nil)');
            n:=IdentifierName(TNodeLet(Result).FOp1);
            ctx:=TContext.Create(nil,localNameSpace,nil);
            try
              localNameSpace.AddConstant(n,TNodeLet(Result).FOp2.Eval(ctx));
            finally
              freeandnil(ctx);
            end;
            freeandnil(result);
            if not VarCanContinueafterComma then
              Append(TNodeIdentifier.Create(n));
          end else if not VarCanContinueafterComma then begin //unnamed const
            tmp:=Result;//save for free
            ctx:=TContext.Create(nil,LocalNameSpace,nil);
            try
              Result:=TNodeConstant.Create(Result.Eval(ctx));
            finally
              FreeAndNil(tmp);
              FreeAndNil(ctx);
            end;
          end else
            CompileError('Expression needed after "Const"');

          if VarCanContinueafterComma then case tk of
            tkComma:continue;
{            tkSemiColon:begin  //nem lehet, mert akkor nem lehet az utasitasok koze rakni
              SaveState;Parse;
              if tk=tkIdentifier then begin
                RestoreState;
                continue;
              end else
                RestoreState;
            end;}
          end;
          break;
        until false;
      end;
      else result:=CompileExpression_NoLocalNameSpace(MustExists);
    end;
  except
    freeandnil(result);raise
  end;
end;

function MakeNodeSequence(const ABlock:TNodeBase):TNodeSequence; //only creates seq if needed
begin
  if(ABlock=nil)or not(ABlock is TNodeSequence)then begin
    result:=TNodeSequence.Create;
    if ABlock<>nil then
      result.AddSubNode(ABlock);
  end else
    result:=TNodeSequence(ABlock);
end;


procedure AppendToNodeSequence(var AResult:TNodeBase;const ANode:TNodeBase);
begin
  if ANode=nil then exit;
  if AResult=nil then
    AResult:=TNodeSequence.Create;
  TNodeSequence(AResult).AddSubNode(ANode);
end;

procedure SimplifyNodeSequence(var ASeq:TNodeBase);
var tmp:TNodeBase;
begin
  if ASeq=nil then exit;
  if(ASeq is TNodeSequence)then with TNodeSequence(ASeq) do
    if(FRequire=nil)and(FEnsure=nil)then
      case SubNodeCount of
        0:FreeAndNil(ASeq);
        1:begin tmp:=SubNode(0); SetSubNode(0,nil); ASeq.free; ASeq:=tmp{innentol nem nyulni ASeq-hez} end;
      end;
end;

function TCompiler.CompileSequence(const AClosingToken:TToken;const AOptions:TCompileSequenceOptions):TNodeBase;
var SequenceCount:integer;

  procedure AddSequence(const n:TNodeBase);
  var tmp:TNodeBase;
  begin
    if n=nil then exit;
    inc(SequenceCount);
    case SequenceCount of
      1:result:=n;
      2:begin
          tmp:=result;
          result:=TNodeSequence.Create;
          TNodeSequence(result).AddSubNode(tmp);
          TNodeSequence(result).AddSubnode(n)
        end;
      else TNodeSequence(result).AddSubnode(n)
    end;
  end;

var isBlock,inEnsure:boolean;
begin
  result:=nil;
  SequenceCount:=0;
  inEnsure:=false;
  try
    while true do begin
      if tk=AClosingToken then begin parse;break end;

      case tk of
        tkSemiColon:parse;
        tkEof:CompileError('unexpected EOF in sequence');
        tkEnsure:begin
          if not(HandleEnsure in AOptions)then CompileError('"ensure" not allowed here.');
          if inEnsure then CompileError('Already inside "ensure" block.');
          parse;
          inEnsure:=true;
          result:=MakeNodeSequence(result);
        end else begin
          isBlock:=tk in[tkRequire,tkBegin];
          if inEnsure then AppendToNodeSequence(TNodeSequence(result).FEnsure,CompileStatement)
                      else AppendToNodeSequence(result,CompileStatement);
          if isBlock and(StopAfterFirstBlock in AOptions)then break;
          if not(tk in[AClosingToken,tkSemiColon]) then CompileError(ansistring('"'+copy(GetEnumName(TypeInfo(TToken),ord(AClosingToken)),3,99)+'" or ";" expected'));
        end;
      end;
    end;

    SimplifyNodeSequence(result);
  except
    result.Free;raise;
  end;
end;

function TCompiler.CompileInnerSetConstruct:TNodeSetConstruct;
var tmp1,tmp2:TNodeBase;r:TNodeRange;
begin
  result:=TNodeSetConstruct.Create;
  tmp1:=nil;
  try
    while true do begin
      tmp1:=nil;

      IgnoreColonInExpression:=true;
      tmp1:=CompileExpression(true);
      if tk=tkPointPoint then begin
        Parse;
        tmp2:=CompileExpression(true);
        r:=TNodeRange.Create;
        r.FOp1:=tmp1;
        r.FOp2:=tmp2;
        result.AddSubNode(r);
      end else begin
        result.AddSubNode(tmp1);
      end;
      case tk of
        tkComma:begin parse;continue;end;
        else Break;
      end;
    end;
  except
    tmp1.free;result.Free;raise;
  end;
end;

function TCompiler.NopIfNil(const n:TNodeBase):TNodeBase;
begin
  if n<>nil then result:=n
            else result:=TNodeNop.Create;
end;

function TCompiler.CompileStatement:TNodeBase;

  function MarkTightlyNested(n:TNodeBase):TNodeBase;
  begin
    result:=n;
    if(n<>nil)and(n is TNodeIteration)then
      TNodeIteration(n).FTightlyNested:=true;
  end;

var require,block:TNodeBase;
    oldTk:TToken;
begin
  result:=nil;
  try
    case tk of
      tkRequire:begin
        parse;
        require:=CompileSequence(tkBegin);
        block:=CompileSequence(tkEnd,[HandleEnsure]);
        if require<>nil then begin
          //make a sequence if needed
          block:=MakeNodeSequence(block);
          TNodeSequence(block).FRequire:=require;
        end;
        result:=block;
      end;
      tkBegin:begin
        parse;
        result:=CompileSequence(tkEnd,[HandleEnsure]);
      end;
      tkIf:begin
        Parse;
        Result:=TNodeIf.Create;
        result.SetSubNode(0,CompileExpression(true));
        if tk<>tkThen then CompileError('"Then" expected');
        parse;
        Result.SetSubnode(1,CompileStatement);
        if tk=tkElse then begin
          parse;
          Result.SetSubNode(2,CompileStatement);
        end;
      end;
      tkRepeat:begin
        parse;
        result:=TNodeRepeat.Create;
        result.SetSubNode(0,MarkTightlyNested(CompileSequence(tkUntil)));
        result.SetSubNode(1,CompileExpression(true));
      end;
      tkWhile:begin
        parse;
        Result:=TNodeWhile.Create;
        result.SetSubNode(0,CompileExpression(true));
        if tk<>tkDo then CompileError('"Do" expected');
        parse;
        result.SetSubnode(1,MarkTightlyNested(CompileStatement));
        if tk=tkUnless then begin
          parse;
          result.SetSubnode(2,CompileStatement);
        end;
      end;
      tkFor:begin
        parse;
        result:=TNodeFor.Create;
        Result.SetSubNode(0,CompileExpression(true));

        if Result.SubNode(0)is TNodeLet then begin
          case tk of
            tkTo:TNodeFor(Result).FForType:=ftTo;
            tkDownTo:TNodeFor(Result).FForType:=ftDownTo;
            tkTowards:TNodeFor(Result).FForType:=ftTowards;
            else CompileError('"To" or "Downto" or "Towards" expected in For');
          end;
          parse;
          //target
          Result.SetSubnode(1,CompileExpression(true));

          //step
          if not(tk in[tkDo,tkStep,tkWhere]) then CompileError('"Do" or "Step" or "Where" expected in For');
          if tk=tkStep then begin
            parse;
            result.SetSubNode(2,CompileExpression(true));
          end else
            result.SetSubNode(2,nil);
        end else if Result.SubNode(0)is TNodeIn then begin
          TNodeFor(Result).FForType:=ftIn;
          if tk=tkDescending then begin
            Parse;
            TNodeFor(Result).FDescending:=true;
          end;
        end else
          CompileError('":=" or "in" expected in For');

        //where
        if not(tk in[tkDo,tkWhere]) then CompileError('"Do" or "Step" expected in For');
        if tk=tkWhere then begin
          parse;
          result.SetSubNode(3,CompileExpression(true));
        end else
          result.SetSubNode(3,nil);

        //loop block
        if tk<>tkDo then CompileError('"Do" expected in For');
        parse;
        Result.SetSubnode(4,MarkTightlyNested(CompileStatement));
        //unless
        if tk=tkUnless then begin
          parse;
          result.SetSubnode(5,CompileStatement);
        end;
      end;
      tkWith,tkUsing:begin
        oldTk:=tk;
        parse;
        Result:=TNodeWith.Create;
        TNodeWith(Result).isUsing := oldTk=tkUsing;
        while true do begin
          TNodeWith(Result).AddSubnode(CompileExpression(true));
          case tk of
            tkComma:begin Parse;Continue end;
            tkDo:begin Parse;break;end;
            else CompileError('"," or "Do" expected in With');
          end;
        end;
        TNodeWith(Result).AddSubnode(CompileStatement);
      end;
      tkCase:begin
        parse;
        Result:=TNodeCase.Create;
        TNodeCase(Result).AddSubnode(CompileExpression(true));
        if tk<>tkOf then CompileError('"Of" expected in Case');
        parse;
        while true do begin
          TNodeCase(result).AddSubNode(CompileInnerSetConstruct);

          if tk<>tkColon then CompileError('":" expected in Case');
          parse;
          TNodeCase(Result).AddSubnode(CompileStatement);
          if tk=tkSemiColon then Parse;
          case tk of
            tkEnd:begin parse;break end;
            tkElse:begin
              Parse;
              TNodeCase(Result).AddSubnode(nil);
              TNodeCase(Result).AddSubnode(CompileSequence(tkEnd));
              break;
            end;
            else continue;
          end;
        end
      end;
      tkProcedure,tkFunction,tkConstructor,tkDestructor:begin
        CompileProcedure('');
      end;
      tkRaise:begin
        parse;
        result:=TNodeRaise.Create;
        result.SetSubNode(0,CompileExpression(true));
      end;
      tkEof:CompileError('Unexpected EOF');
      else
        result:=CompileExpression(false,true{var definitions});
    end;
  except
    result.Free;raise;
  end;
end;

procedure TCompiler.CompileProcedure;

  var ProcName,ClassT:ansistring;
      ProcType:TToken;
  function CompileProcHeader(const OuterClassT:ansistring):ansistring;//local namespace-ba rakja
  var Params:AnsiString;
      ch0:PAnsiChar;
  begin
    if LocalNameSpace=nil then
      CompileError('Cannot compile procedures without localnamespace');

    ProcType:=Expect(tkProcedure,tkFunction,tkConstructor,tkDestructor);

    parse;

    Expect(tkIdentifier,tkPointPoint);ProcName:=val;parse;

    if tk=tkPoint then begin
      if OuterClassT<>'' then CompileError('Class specifier not allowed here.');
      ClassT:=ProcName;
      parse;
      Expect(tkIdentifier);ProcName:=val;parse;
    end else
      ClassT:=OuterClassT;
    //ProcName,ClassT are valid

    if tk=tkBracketOpen then begin//parameters
      ch0:=pointer(ch);//nagy ták
      repeat
        parse;
      until tk in[tkEof,tkBracketClose];
      Expect(tkBracketClose);
      setlength(params,integer(ch)-integer(ch0)+1);if Params<>'' then move(ch0[-1],Params[1],length(Params));
      parse;
    end;

    result:={copy(GetEnumName(TypeInfo(TToken),ord(ProcType)),3,$ff)+' '+}switch(ClassT<>'',ClassT+'.','')+ProcName+Params;
    expect(tkSemiColon);
    parse;
  end;

var hdr:AnsiString;
    n:TNodeBase;
    ns,nsParent:TNameSpace;
begin
  hdr:=CompileProcHeader(OuterClassT);
  nsParent:=LocalNameSpace;

  ns:=TNameSpace.Create(switch(ClassT<>'',ClassT+'.'+ProcName,ProcName));
  ns.FParent:=nsParent;
  if ProcType in [tkFunction,tkConstructor]then begin
    ns.AddOrFree(TNameSpaceResult.Create('result'));

    //ns.AddOrFree(TNameSpaceResult.Create(ProcName));
    //   Ez amiatt lett torolve, hogy lehessen rekurziv funkciokat hivni, mert
    //   jelenleg a kereses csak NEV es PARAMCOUNT es IndexOrNot alapjan megy
    //   Arrol nincs info, hogy ertekadas tortenik-e. Kulonben is, ezt a fajra
    //   result megadast ospascal ota sosem hasznaltam...
  end;

  LocalNameSpace:=ns;
  try
    n:=CompileSequence(tkEof,[StopAfterFirstBlock]);
    nsParent.AddOrFree(TNameSpaceScriptFunction.Create(hdr,ns,n));
    LocalNameSpace:=nsParent;
  except
    ns.Free;raise;
  end;
end;

function CompilePascalProgram(const ASrc:ansistring;const ALocalNS:TNameSpace):TNodeBase;

  function GetModuleName:string;
  begin
    if AlocalNS=nil then exit('');
    ALocalNS.GetFullName;
  end;

var c:TCompiler;
    msg,cat:string;
begin
  result:=nil;
  if ASrc='' then exit;
  c:=TCompiler.Create;
  c.LocalNameSpace:=ALocalNS;
  try
    try
      c.ch:=pointer(ASrc);c.chStart:=pointer(c.ch);c.parse;
      result:=c.CompileSequence(tkEof);
    except
      on e:Exception do begin
        //attach position info to error
        msg:=e.Message;
        if e is EScriptError then cat:=EScriptError(e).Category
                             else cat:=e.ClassName;
        raise EScriptError.Create(msg,cat,ALocalNS.GetFullName,
          ParseCountChars(c.chStart,c.ch,#10),
          integer(c.ch)-integer(c.chStart),0);
      end;
    end;
  finally
    c.Free;
  end;
end;

// -----------------------------------------------------------------------------
// Context                                                                    //
// -----------------------------------------------------------------------------

constructor TContext.Create(const APrevContext:TContext;const ANameSpace:TNameSpace;const AParams:TNodeParamList;const AWithObject:TObject=nil);
begin
  PrevContext:=APrevContext;

  if PrevContext<>nil then RootContext:=PrevContext.RootContext
                      else RootContext:=self;

  nsLocal:=ANameSpace;

  if AWithObject<>nil then
    WithStack.Append(AWithObject);

  BlockPostfixAssignments:=false;
  PendingPostfixOperations.FCount:=0;

  ResultValue:=Null;

  FParams:=AParams;

  if RootContext=self then
    FStdOutBuilder:=AnsiStringBuilder(FStdOut,true);
end;

function TContext.AcquireNameSpaceEntry(const AName:AnsiString;const AIsIndex:boolean;const AParamCount:integer;const ASelfObj:TObject=nil):TNameSpaceEntry;

  function FindInCurrentScope(const AName:ansistring):TNameSpaceEntry;
  begin
    result:=nsLocal.FindByNameReqursive(AName);
  end;

  function FindForClassNonOle(const ASelfObj:TObject):TNameSpaceEntry;
  var FullName:ansistring;
      pi,lastPi:PPropInfo;
      cl,lastClass:TClass;

      rt:TRttiType;
      rm:TRttiMember;
  begin
    //class function or cached thing?
    if ASelfObj is TClassReference then cl:=TClassReference(ASelfObj).ReferencedClass
                                   else cl:=ASelfObj.ClassType;

    while cl<>nil do begin
      FullName:=ansistring(cl.ClassName)+ansichar('.')+AName;
      result:=FindInCurrentScope(FullName);  //defined?  <- na ez nem biztos, hogy ide kellene
      if result<>nil then exit;
      result:=nsObjectProperties.FindByName(FullName); //cached?
      if result<>nil then exit;

      rt:=rtticontext.GetType(cl);
      if rt<>nil then begin
        rm:=rt.GetMethod(AName);
        if(rm<>nil)and(rm.Visibility>=mvPublic)
        and(TRttiMethod(rm).MethodKind in[mkClassProcedure,mkClassFunction,mkClassConstructor,mkClassDestructor,mkConstructor])then begin
          Result:=TNameSpaceRTTIMember.Create(rm);
          nsObjectProperties.Add(Result);
          exit;
        end;
      end;

      cl:=cl.ClassParent;
    end;

    //uncached property? (if so, then put into the cache)
    cl:=ASelfObj.ClassType;lastPi:=nil;lastClass:=nil;
    while cl<>nil do begin
      pi:=GetPropInfo(cl,string(AName));
      if pi<>nil then begin lastPi:=pi;lastClass:=cl end
                 else break;
      cl:=cl.ClassParent;
    end;
    if lastPi<>nil then begin
      result:=TNameSpaceObjectProperty.Create(lastClass,AName,lastPi);
      nsObjectProperties.Add(result);
      exit;
    end;

    //uncached newRTTI thing?
    cl:=ASelfObj.ClassType;
    while cl<>nil do begin
      rt:=rtticontext.GetType(cl);
      if rt<>nil then begin

        rm:=rt.GetProperty(AName);
        if rm=nil then rm:=rt.GetMethod(AName);

        if(rm<>nil)and(rm.Visibility>=mvPublic)then begin
          Result:=TNameSpaceRTTIMember.Create(rm);
          nsObjectProperties.Add(Result);
          exit;
        end;

      end;
      cl:=cl.ClassParent;
    end;

    //TComponent.ComponentbyName?
    if ASelfObj is TComponent then with TComponent(ASelfObj) do if FindComponent(AName)<>nil then begin
      result:=TNameSpaceObjectComponent.Create(AName,ASelfObj.ClassType);
      nsObjectProperties.Add(result);
      exit;
    end;

    //not found
    result:=nil;
  end;

  function FindForClassOle(const ASelfObj:TObject):TNameSpaceEntry;
  var test:IDispatch;
  begin
    //VariantInvoker?
    if ASelfObj is TVariantInvoker then begin
      Result:=nsVariantInvoker.FindByName(ASelfObj.ClassName+'.'+AName);
      if result=nil then begin
        Result:=TNameSpaceVariantInvoker.Create(AName+'(...)',ASelfObj.ClassType);
        nsVariantInvoker.Add(result);
      end;
      exit;
    end;

    //TObject as IDispatch?
    if ASelfObj.GetInterface(IID_DISPATCH,test)then begin
      Result:=nsVariantInvoker.FindByName('TObject.'+AName);
      if result=nil then begin
        Result:=TNameSpaceObjectInvoker.Create(AName+'(...)',TObject);
        nsVariantInvoker.Add(result);
      end;
      exit;
    end;

    //not found
    result:=nil;
  end;

  procedure ParamCountError(const ATooMany:boolean);
  const Strings:array[boolean]of string=('Not enough actual parameters. ','Too many actual parameters. ');
  begin
    ExecError(Strings[ATooMany]+topas(Result.FFullName));
  end;

var i:integer;
begin
  if ASelfObj<>nil then begin
    //mindenkeppen class.valami
    result:=FindForClassNonOle(ASelfObj);
    //ole
    if result=nil then
      result:=FindForClassOle(ASelfObj);
  end else begin
    //withs
    result:=nil;
    for i:=WithStack.FCount-1 downto 0 do if WithStack.FItems[i]<>nil then begin
      result:=FindForClassNonOle(WithStack.FItems[i]);
      if result<>nil then break;
    end;
    //non object
    if result=nil then
      result:=FindInCurrentScope(AName);
    //a mindenre jo nsObjectProperties
    if result=nil then
      result:=nsObjectProperties.FindByName(AName);
    //ole
    if result=nil then
      for i:=WithStack.FCount-1 downto 0 do if WithStack.FItems[i]<>nil then begin
        result:=FindForClassOle(WithStack.FItems[i]);
        if result<>nil then exit;//no check
      end;
  end;

  //not found
  if result=nil then begin
    if ASelfObj=nil then ExecError('Unable to resolve identifier '+topas(AName))
                    else ExecError('Unable to resolve identifier '+topas(ASelfObj.ClassName+'.'+AName));
  end;

  //no constructor call allowed for instances
  if(result is TNameSpaceObjectConstructor)and((ASelfObj=nil)or not(ASelfObj is TClassReference)) then
    ExecError('Cannot call constructor for object instance');

  //checking for index or function
  if AIsIndex then begin
    if result.IsIndex and not result.ParamCountSupported(AParamCount)then ParamCountError(AParamCount>length(Result.FParams));
    if not result.IsIndex and not result.ParamCountSupported(0)then ParamCountError(true);
  end else begin
    if Result.IsIndex then ParamCountError(false);
    if not result.ParamCountSupported(AParamCount)then ParamCountError(AParamCount>length(Result.FParams));
  end;
end;

destructor TContext.Destroy;
begin
  if FBreakCnt<>0 then
    ExecError('Invalid use of "Break". (breakCnt is '+tostr(FBreakCnt)+' at end of proc/funct block.)');

  FStdOutBuilder:=nil;//drop the intf
  inherited;
end;

procedure TContext.FinalizePostfixOperations(const AFrom:integer);
var i:integer;
begin
  with PendingPostfixOperations do begin
    for i:=AFrom to FCount-1 do
      FItems[i].PostfixFinalize(self);
    //Clear;
    FCount:=AFrom;//nem clear, mert nem freememezunk
  end;
end;

function TContext.FindContext(const ANameSpace: TNameSpace):TContext;
begin
  result:=self;
  while true do begin
    if result=nil then ExecError('StackFrame not found for NameSpace '+topas(ANameSpace.FullName));
    if result.nsLocal=ANameSpace then exit;
    result:=result.PrevContext;
  end;
end;

function TContext.ParamCount: integer;
begin
  result:=FParams.ParamCount;
end;

procedure TContext.SetupOneWith(const AWith: TObject);
begin
  if AWith<>nil then begin
    if WithStack.FCount=1 then WithStack.FItems[0]:=AWith
                          else begin WithStack.Clear;WithStack.Append(AWith);end;
  end else
    WithStack.Clear;
end;

function TContext.GetStdOut: ansistring;
begin
  RootContext.FStdOutBuilder.Finalize;
  result:=RootContext.FStdOut;
end;

procedure TContext.StdOutWrite(const s: ansistring);
begin
  RootContext.FStdOutBuilder.AddStr(s);
end;

function TContext.Dump:ansistring;
begin
  result:=format('ctx:%8x root:%8x prev:%8x ns:%s ',[integer(self),integer(RootContext),integer(PrevContext),nsLocal.GetFullName])+#13#10;
end;

function TContext.EvalParamUncached(const AIdx: integer): variant;
begin
  FParams.EvalParam(PrevContext,Result,AIdx);
end;

function TContext.EvalParam(const AIdx: integer): variant;
begin
  if not VarIsEmpty(FLocalValues[AIdx])then begin//lazy eval
    Result:=FLocalValues[AIdx];
  end else begin//eval
    FParams.EvalParam(PrevContext,Result,AIdx);
    FLocalValues[AIdx]:=Result;
  end;
end;

procedure TContext.LetParam(const AIdx: integer; const AValue:variant);
begin
  if cardinal(AIdx)>=cardinal(FParams.SubNodeCount) then
    ExecError('Error writing into function_parameter: idx out of range'+tostr(AIdx));
  FParams.SubNode(AIdx).Let(PrevContext,AValue);
  FLocalValues[AIdx]:=Unassigned;{Azert nem AValue, mert var-nal, out-nal nem szabad cacheolni!!!!!}
end;

function TContext.ExecMask: boolean;
begin
  result:=not FExiting and not FContinueing and(FBreakCnt=0);
end;

procedure TContext.ExitContext;
begin
  FExiting:=true;
end;

procedure TContext.ExitContext(const AResult: variant);
begin
  ResultValue:=AResult;
  ExitContext;
end;

procedure TContext.BreakContext;
begin
  if blockcnt<0 then ExecError('Invalid break(count), count can''t be negative.');
 
  inc(FBreakCnt,blockcnt);
end;

procedure TContext.ContinueContext;
begin
  FContinueing:=true;
end;

// -----------------------------------------------------------------------------
// Namespaces                                                                 //
// -----------------------------------------------------------------------------

{ TNameSpaceEntry }

constructor TNameSpaceEntry.Create(const ADefinition: ansistring;const ABaseClass:TClass=nil);
begin

  ProcessDefinition(ADefinition,ABaseClass);
end;

procedure TNameSpaceEntry.ProcessDefinition(const ADefinition:ansistring;const ABaseClass:TClass);

  procedure Error(const s:string);
  begin
    NameSpaceError('ProcessDefinition() '+s);
  end;

var ParamLength:integer;
  procedure AddParam(const AName:ansistring;const ADefault:variant;const AParamType:TParameterType);
  begin
    if length(FParams)<=ParamLength then
      setlength(FParams,length(FParams)*2);
    with FParams[ParamLength]do begin
      Name:=AName;
      Default:=ADefault;
      Typ:=AParamType;
    end;
    inc(ParamLength);
  end;

var ch:PAnsiChar;
    s,s2:ansistring;
    def,val:variant;
    ParamType:TParameterType;
    ParamTypeAllowed:boolean;
begin
  //Definition syntax: id(x,y,z=0,...)   := []
  FName:='';FFullName:='';
  FBaseClass:=ABaseClass;
  FIsIndex:=false;
  SetLength(FParams,8);ParamLength:=0;
  FInfiniteParams:=false;

  if ADefinition='' then Error('Def=""');
  ch:=pointer(ADefinition);

  //Identifier can be a number to for DispID
  ParseSkipWhitespaceAndComments(ch);
  s:='';
  if not ParseIdentifier(ch,s)then begin
    val:=ParsePascalConstant(ch);
    if VarIsOrdinal(val)then s:=IntToStr(val)
  end;
  if s='' then Error('Identifier expected');
  FName:=s;

  ParseSkipWhitespaceAndComments(ch);
  if FBaseClass<>nil then FFullName:=FBaseClass.ClassName+'.'+FName
                     else FFullName:=FName;
  FHash:=Crc32UC(FFullName);

  if ch^ in['(','[']then begin
    FIsIndex:=ch^='[';
    inc(ch);ParseSkipWhitespaceAndComments(ch);

    ParamType:=ptLocal;
    ParamTypeAllowed:=true;
    while true do begin
      if ParseIdentifier(ch,s)then begin
        if ParamTypeAllowed then begin
          if cmp(s,'var'  )=0 then ParamType:=ptVar else
          if cmp(s,'const')=0 then ParamType:=ptConst else
          if cmp(s,'out'  )=0 then ParamType:=ptOut else
            ParamType:=ptLocal;
          if ParamType<>ptLocal then begin
            ParseSkipWhitespaceAndComments(ch);
            if not ParseIdentifier(ch,s)then
              CompileError('Identifier expected');
          end;
          ParamTypeAllowed:=false;
        end;
        ParseSkipWhitespaceAndComments(ch);

        if ch^=':' then begin//skip type
          inc(ch);
          ParseIdentifier(ch,s2);
          ParseSkipWhitespaceAndComments(ch);
        end;

        if (ch[0]='='){or((ch[0]=':')and(ch[1]='=')}then begin
{          if ch[0]=':' then inc(ch);}
          inc(ch);
          ParseSkipWhitespaceAndComments(ch);
          if ParseIdentifier(ch,s2)then begin
            if cmp(s2,'Unassigned')=0 then def:=Unassigned else
            if cmp(s2,'Null')=0 then def:=Null else
            if cmp(s2,'nil')=0 then def:=VObject(nil)else //lame... must be replaced with eval
            if cmp(s2,'nilRef')=0 then def:=VReference(nil)else
            if cmp(s2,'true')=0 then def:=true else
            if cmp(s2,'false')=0 then def:=false else
              Error('Invalid simple constant');
          end else begin
            def:=ParsePascalConstant(ch);
            if VarIsEmpty(def)then
              Error('Invalid simple constant');
          end;
          AddParam(s,def,ParamType);
          ParseSkipWhitespaceAndComments(ch);
        end else
          AddParam(s,Unassigned,ParamType);
      end else if (ch[0]='.')and(ch[1]='.')and(ch[2]='.')then begin
        Inc(ch,3);
        FInfiniteParams:=true;
      end;

      if ch^in[',',';']then begin
        if FInfiniteParams then Error('No params allowed after "..." ');
        ParamTypeAllowed:=ch^=';';
        inc(ch);
        ParseSkipWhitespaceAndComments(ch);
        continue;
      end;

      if FIsIndex then begin
        if ch^=']'then begin inc(ch);break end;
      end else begin
        if ch^=')'then begin inc(ch);break end;
      end;
      Error('Invalid char');
    end;
  end;
  SetLength(FParams,ParamLength);
end;

function TNameSpaceEntry.ParamListAsVariantArray(const AParamList:TNodeParamList;const AContext:TContext):TVariantArray;
var i:integer;
begin
  setlength(result,0);

  SetLength(result,max(AParamList.ParamCount,Length(FParams)));
  if result=nil then exit;

  for i:=0 to high(FParams)do begin
    AParamList.EvalParam(AContext,Result[i],i);
    if VarIsEmpty(Result[i])then
      Result[i]:=FParams[i].Default;  //defaults
  end;

  //variable count params
  for i:=length(FParams)to high(result)do
    AParamList.EvalParam(AContext,Result[i],i);
end;

function TNameSpaceEntry.ObjectSupported(const AObj:TObject):boolean;
begin
  if IsConstructor then
    result:=(FBaseClass<>nil)and(AObj is TClassReference)and(FbaseClass=TClassReference(AObj).ReferencedClass)
  else
    result:=(FBaseClass<>nil)and(AObj is FBaseClass);
end;

function TNameSpaceEntry.ParamCountSupported(const AParamCount:integer):boolean;
begin
  result:=(AParamCount=Length(FParams))
        or((AParamCount<Length(FParams))and not VarIsEmpty(FParams[AParamCount].Default))
        or((AParamCount>Length(FParams))and FInfiniteParams);
end;

function TNameSpaceEntry.SelectCompatibleObjectFromWithStack(const AObj:TObject;const AContext:TContext;const mustExists:boolean):TObject;
var i:integer;
begin
  result:=AObj;
  if result<>nil then exit;

  if FBaseClass<>nil then begin
    with AContext do for i:=WithStack.FCount-1 downto 0 do begin
      result:=WithStack.FItems[i];
      if(result<>nil)and ObjectSupported(result)then
        exit;
    end;
  end;

  result:=nil;
  if mustExists then
    raise Exception.Create('Object is nil');
end;

function TNameSpaceEntry.Dump(const AIndent: integer): ansistring;
begin
  if Self=nil then result:=''
              else result:=Indent('   ',AIndent)+FFullName+':'+ClassName+#13#10;
end;

procedure TNameSpaceEntry.Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  ExecError(ClassName+'.Eval() not implemented ('+string(FName)+')');
end;

procedure TNameSpaceEntry.Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  ExecError(ClassName+'.Let() not implemented ('+string(FName)+')');
end;

procedure TNameSpaceEntry.Ref(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList;const AErrorIfCant:boolean);
begin
  if AErrorIfCant then ExecError(ClassName+'.GetRef() not implemented ('+string(FName)+')')
                  else Eval(AResult,AContext,AObj,AParams);
  //!!!!!! Azert ad vissza Eval-t, hogy a cal.devices.ByIndex[0] mukodjon, ubergáz
end;

{ TNameSpaceConstant }

constructor TNameSpaceVariable.Create(const ADefinition: ansistring; const AValue: Variant);
begin
  inherited Create(ADefinition,nil);
  FValue:=AValue;
end;

procedure TNameSpaceVariable.Eval;
begin
  AResult:=FValue;
end;

procedure TNameSpaceVariable.Let;
begin
  FValue:=AValue;
end;

procedure TNameSpaceVariable.Ref(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList;const AErrorIfCant:boolean);
begin
  AResult:=VReference(FValue);
end;

function TNameSpaceVariable._ValuePtr:PVariant;
begin
  result:=@FValue;
end;

{ TNameSpaceConstant }

procedure TNameSpaceConstant.Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  ExecError('Cannot write readonly variable '+toPas(FName));
end;

{ TNameSpaceFunction }

constructor TNameSpaceFunction.Create(const ADefinition:ansistring;const AEval:TEvalFunct;const ALet:TLetProc=nil);
begin
  inherited Create(ADefinition,nil);
  FEval:=AEval;
  FLet:=ALet;
end;

procedure TNameSpaceFunction.Eval;
begin
  AResult:=FEval(ParamListAsVariantArray(AParams,AContext));
end;

procedure TNameSpaceFunction.Let;
begin
  if not Assigned(FLet)then ExecError('Cannot write into a readonly function');
  FLet(ParamListAsVariantArray(AParams,AContext),AValue);
end;

{ TNameSpaceCtxFunction }

constructor TNameSpaceCtxFunction.Create(const ADefinition:ansistring;const AEval:TEvalCtxFunct;const ALet:TLetCtxProc=nil);
begin
  inherited Create(ADefinition,nil);
  FEval:=AEval;
  FLet:=ALet;
end;

procedure TNameSpaceCtxFunction.Eval;
begin
  AResult:=FEval(AContext,ParamListAsVariantArray(AParams,AContext));
end;

procedure TNameSpaceCtxFunction.Let;
begin
  if not Assigned(FLet)then ExecError('Cannot write into a readonly function');
  FLet(AContext,ParamListAsVariantArray(AParams,AContext),AValue);
end;

{ TNameSpaceVectorFunction }

procedure TNameSpaceVectorFunction.Eval;
var Params:TVariantArray;

  function OpLen(n:integer):integer;
  begin
    if TVarData(Params[n]).VType=varVariant+varArray then
      result:=VarArrayAsPSafeArray(Params[n]).Bounds[0].ElementCount
    else
      result:=1;
  end;

  function Op(n,m:integer):integer;
  begin
    if TVarData(Params[n]).VType=varVariant+varArray then
      if OpLen(n)=1 then result:=VarArrayAccess(params[n],0)^
                    else result:=VarArrayAccess(params[n],m)^
    else
      result:=params[n];
  end;

var actParams:TVariantArray;
    isVect:boolean;
    i,j:integer;
    Bounds:array of integer;
begin
  params:=ParamListAsVariantArray(AParams,AContext);

  //is there any arrays?
  isVect:=false;
  for i:=0 to high(params)do
    if TVarData(Params[i]).VType=varVariant+varArray then
      begin isVect:=true;break end;

  if not isVect then begin
    AResult:=FEval(params)
  end else begin
    //calc vectorsize, alloc result
    setlength(Bounds,2);
    Bounds[0]:=0;Bounds[1]:=1;
    for i:=0 to high(params)do begin
      j:=OpLen(i);
      if j<>1 then begin Bounds[1]:=j-1;break end;
    end;
    AResult:=VarArrayCreate(Bounds,varVariant);

    //make temp params array, fill with scalars
    setlength(actParams,length(params));
    for i:=0 to high(actParams)do if OpLen(i)=1 then
      actParams[i]:=Op(i,0);

    for i:=0 to Bounds[1]do begin
      //fill vector params
      for j:=0 to high(params)do if OpLen(j)<>1 then
        ActParams[j]:=Op(j,i);

      VarArrayAccess(AResult,i)^:=FEval(ActParams);
    end;
  end;
end;

procedure TNameSpaceVectorFunction.Let;
begin
  ExecError('Cannot write into a vectorFunction '+topas(FName));
end;

{ TNameSpaceObjectFunction }

constructor TNameSpaceObjectFunction.Create(const ABaseClass:TClass;const ADefinition:ansistring;const AEval:TEvalObjectFunct;const ALet:TLetObjectProc=nil);
begin
  inherited Create(ADefinition,ABaseClass);
  FEval:=AEval;
  FLet:=ALet;
end;

procedure TNameSpaceObjectFunction.Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  AResult:=FEval(SelectCompatibleObjectFromWithStack(AObj,AContext,true),
                 ParamListAsVariantArray(AParams,AContext));
end;

procedure TNameSpaceObjectFunction.Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  if not Assigned(FLet)then ExecError('Cannot write into a readonly object.function');
  FLet(SelectCompatibleObjectFromWithStack(AObj,AContext,true),
       ParamListAsVariantArray(AParams,AContext),AValue);
end;

{ TNameSpaceObjectConstructor }

constructor TNameSpaceObjectConstructor.Create(const ABaseClass:TClass;const ADefinition:ansistring;const AConstructor:TObjectConstructFunct);
begin
  inherited Create(ADefinition,ABaseClass);
  FIsConstructor:=true;
  FConstructor:=AConstructor;
end;

procedure TNameSpaceObjectConstructor.Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  AResult:=VObject(FConstructor({SelectCompatibleObjectFromWithStack(AObj,AContext,true)}ParamListAsVariantArray(AParams,AContext)));
end;

{ TNameSpaceObjectProperty }

constructor TNameSpaceObjectProperty.Create(const ABaseClass:TClass;const ADefinition:ansistring;const APropInfo:PPropInfo);
begin
  inherited Create(ADefinition,ABaseClass);
  FPropInfo:=APropInfo;
end;

procedure TNameSpaceObjectProperty.Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
var cd:TClassDescription;
//    o:TObject;
begin
  if AContext.FPropQuery=pqNone then
    AResult:=GetPropValue(SelectCompatibleObjectFromWithStack(AObj,AContext,true),FPropInfo,false)
  else begin
{    o:=SelectCompatibleObjectFromWithStack(AObj,AContext,true);
    if o=nil then begin AResult:=Null;exit end;}
    cd:=ClassDescriptionOf(FBaseClass);
    case AContext.FPropQuery of
      pqDefault:AResult:=cd.DefaultOf(FPropInfo);
      pqRangeMin:AResult:=cd.RangeMinOf(FPropInfo);
      pqRangeMax:AResult:=cd.RangeMaxOf(FPropInfo);
    else Aresult:=Null; end;
  end;
end;

procedure TNameSpaceObjectProperty.Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  SetPropValue(SelectCompatibleObjectFromWithStack(AObj,AContext,true),FPropInfo,AValue);
end;

{ TNameSpaceComponent }

procedure TNameSpaceObjectComponent.Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
var i:integer;o:TObject;
begin
  MonitorEnter(self);//possible multithreading
  try
    o:=SelectCompatibleObjectFromWithStack(AObj,AContext,true);
    with FCache do begin
      if(owner<>o)or(idx>=owner.ComponentCount)or(owner.Components[idx]<>component)then begin
        if FUnicodeName='' then
          FUnicodeName:=FName;

        owner:=TComponent(o);
        component:=nil;
        for i:=0 to owner.ComponentCount-1 do
          if SameText(owner.Components[i].Name,FUnicodeName) then begin
            component:=owner.Components[i];
            idx:=i;
            break;
          end;
      end;
      AResult:=VObject(component);
    end;
  finally
    MonitorExit(self);
  end;
end;

{ TNameSpaceVariantInvoker }

procedure TNameSpaceVariantInvoker.Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  AResult:=TVariantInvoker(SelectCompatibleObjectFromWithStack(AObj,AContext,true)).
    Invoke(dkMethod,FName,ParamListAsVariantArray(AParams,AContext));
end;

function OneParamList(const v:variant):TVariantArray;
begin
  setlength(result,1);
  result[0]:=v;
end;

procedure TNameSpaceVariantInvoker.Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  TVariantInvoker(SelectCompatibleObjectFromWithStack(AObj,AContext,true)).
    Invoke(dkPropertySet,FName,OneParamList(AValue));
end;

procedure TNameSpaceVariantInvoker.Ref(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList;const AErrorIfCant:boolean);
begin
  AResult:=TVariantInvoker(SelectCompatibleObjectFromWithStack(AObj,AContext,true)).
    Invoke(dkGetReference,FName,nil);
end;


{ TNameSpaceObjectInvoker }

procedure TNameSpaceObjectInvoker.Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
var obj:TObject;
    Disp:IDispatch;
begin
  obj:=SelectCompatibleObjectFromWithStack(AObj,AContext,true);
  if obj is TOleControl then begin
    AResult:=MyDispatchInvoke(TOleControl(obj).DefaultDispatch,dkMethod,FName,ParamListAsVariantArray(AParams,AContext));
  end else begin
    if obj.GetInterface(IID_DISPATCH,Disp)then
      AResult:=MyDispatchInvoke(Disp,dkMethod,FName,ParamListAsVariantArray(AParams,AContext));
  end;
end;

procedure TNameSpaceObjectInvoker.Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  ExecError('TNameSpaceObjectInvoker assignments not yet supported');
end;

{ TNameSpaceRTTIMember }

constructor TNameSpaceRTTIMember.Create(const ARTTIMember:TRttiMember);
var ct:TClass;
    def,params:ansistring;
    p:TRttiParameter;
begin
  FMember:=ARTTIMember;
  ct:=TRttiInstanceType(FMember.Parent).MetaclassType;

  if FMember is TRttiProperty then begin
    def:=FMember.Name;
  end else if FMember is TRttiMethod then begin
    //get paramlist
    for p in TRttiMethod(FMember).GetParameters do begin
      ListAppend(params,p.Name,',');
      //no way to acces optional parameters :(

      //accessing enumerated types tho
      if(p.ParamType<>nil)then case p.ParamType.TypeKind of
        tkEnumeration:if nsObjectProperties.FindByName(p.ParamType.Handle.Name)=nil then nsObjectProperties.AddEnum(p.ParamType.Handle);
        tkSet:if nsObjectProperties.FindByName(p.ParamType.Handle.Name)=nil then nsObjectProperties.AddSet(p.ParamType.Handle);
      end;
    end;
    def:=FMember.Name+'('+params+')';
  end else
    raise Exception.Create('TNameSpaceRTTIMember.Create() Unknown RTTIObject: '+FMember.ClassName);

  inherited Create(def,ct);
end;

function RTTIValueToVar(const V:TValue):Variant;
begin
  if V.IsObject then exit(VObject(V.AsObject));
  if V.IsClass then exit(VClass(V.AsClass));
  if V.IsEmpty then exit(Null);
  if V.IsType<Boolean> then exit(V.AsType<Boolean>);
  if V.Kind=tkEnumeration then exit(VEnum(V.AsOrdinal,V.TypeInfo));
  //set majd kesobb
  result:=V.AsVariant;
end;

function VarToRttiValue(const V:Variant):TValue;
begin
  if VarIsObject(V)then exit(VarAsObject(V));
  if VarIsClass(V)then exit(VarAsClass(V));
  if VarIsEnum(V) then  exit(TValue.FromOrdinal(VarEnumType(V),integer(V)));
  //set majd kesobb
  Result:=TValue.FromVariant(V);
end;

procedure TNameSpaceRTTIMember.Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
var obj:TObject;
    args:array of TValue;
    i:integer;
    rm:TRttiMethod;
begin
  obj:=SelectCompatibleObjectFromWithStack(AObj,AContext,true);
  if FMember is TRttiProperty then
    AResult:=RTTIValueToVar(TRttiProperty(FMember).GetValue(obj))
  else begin
    rm:=TRttiMethod(FMember);
    //get params
    if AParams<>nil then begin
      setlength(args,AParams.ParamCount);
      for i:=0 to high(args)do
        args[i]:=VarToRttiValue(AParams.EvalParam(AContext,i));
    end else
      SetLength(args,0);

    //invoke class.methot, obj.metod, obj.staticmethod
    if rm.MethodKind in[mkClassProcedure, mkClassFunction, mkClassConstructor, mkClassDestructor,
                        mkConstructor{na ez miert nincs benne...}]then
      if obj is TClassReference then
        AResult:=RTTIValueToVar(rm.Invoke(TClassReference(obj).ReferencedClass,args))
      else
        AResult:=RTTIValueToVar(rm.Invoke(obj.ClassType,args))
    else
      AResult:=RTTIValueToVar(rm.Invoke(obj,args));
  end;
end;

procedure TNameSpaceRTTIMember.Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
var obj:TObject;
begin
  obj:=SelectCompatibleObjectFromWithStack(AObj,AContext,true);
  if FMember is TRttiProperty then
    TRttiProperty(FMember).SetValue(obj,VarToRttiValue(AValue))
  else
    raise Exception.Create('Error assigning value to RTTIMethod '+FFullName);
end;

{procedure TNameSpaceRTTIMember.Ref(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList;const AErrorIfCant:boolean);
begin
  Eval(AResult,AContext,AObj,nil);
end;}

{ TNameSpaceLocalVariable }

constructor TNameSpaceLocalVariable.Create(const ADefinition: ansistring;const AIndex:integer);
begin
  inherited create(ADefinition,nil);
  FIndex:=AIndex;
end;

procedure TNameSpaceLocalVariable.Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  with AContext.FindContext(FNameSpace)do
    AResult:=FLocalValues[high(FLocalValues)-FIndex];
end;

procedure TNameSpaceLocalVariable.Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  with AContext.FindContext(FNameSpace)do
    FLocalValues[high(FLocalValues)-FIndex]:=AValue;
end;

procedure TNameSpaceLocalVariable.Ref(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList;const AErrorIfCant:boolean);
begin
  with AContext.FindContext(FNameSpace)do
    AResult:=VReference(FLocalValues[high(FLocalValues)-FIndex]);
end;

{ TNameSpaceParameter }

constructor TNameSpaceParameter.Create(const ADefinition:ansistring;const AIndex:integer;const ADefault:variant;const AType:TParameterType);
begin
  inherited Create(ADefinition,nil);
  FIndex:=AIndex;
  FDefault:=ADefault;
  FType:=AType;

  FCacheable:=FType in[ptLocal,ptConst];
end;

procedure TNameSpaceParameter.Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  with AContext.FindContext(FNameSpace)do begin
    if FCacheable then Aresult:=EvalParam(FIndex)
                  else Aresult:=EvalParamUncached(FIndex);
  end;
end;

procedure TNameSpaceParameter.Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
var ctx:TContext;
begin
  ctx:=AContext.FindContext(FNameSpace);

  case FType of
    ptLocal:ctx.FLocalValues[FIndex]:=AValue;
    ptVar,ptOut:ctx.LetParam(FIndex,AValue);
    ptConst:ExecError('Cannot write into constant parameter '+toPas(FFullName));
  end;
end;

procedure TNameSpaceParameter.Ref(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList;const AErrorIfCant:boolean);
var ctx:TContext;
begin
  ctx:=AContext.FindContext(FNameSpace);

  case FType of
    ptLocal,ptConst:begin
      if VarIsEmpty(ctx.FLocalValues[FIndex])then begin
        if FIndex<ctx.FParams.SubNodeCount then
          ctx.FParams.EvalParam(ctx.PrevContext,AResult,FIndex)
        else
          AResult:=FDefault;
        ctx.FLocalValues[FIndex]:=AResult;
      end;
      AResult:=VReference(ctx.FLocalValues[FIndex]);
    end;
    ptVar,ptOut:ctx.FParams.SubNode(FIndex).Ref(ctx.PrevContext,true,AResult);
  end;
end;

{ TNameSpaceResult }

constructor TNameSpaceResult.Create(const AName: ansistring);
begin
  inherited Create(AName);
end;

procedure TNameSpaceResult.Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  AResult:=AContext.FindContext(FNameSpace).ResultValue;
end;

procedure TNameSpaceResult.Let(const AValue:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  AContext.FindContext(FNameSpace).ResultValue:=AValue;
end;

procedure TNameSpaceResult.Ref(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList;const AErrorIfCant:boolean);
begin
  AResult:=VReference(AContext.FindContext(FNameSpace).ResultValue);
end;

{ TNameSpaceScriptFunction }

constructor TNameSpaceScriptFunction.Create(const ADefinition:ansistring;const ANameSpace:TNameSpace;const ABody:TNodeBase);
var i:integer;
begin
  inherited Create(ADefinition,nil);
  FProcNameSpace:=ANameSpace;
  FBody:=ABody;

  FLocalValueCount:=0;
  with FProcNameSpace do
    for i:=0 to FList.FCount-1 do if FList.FItems[i] is TNameSpaceLocalVariable then begin
      TNameSpaceLocalVariable(FList.FItems[i]).FIndex:=FLocalValueCount;
      inc(FLocalValueCount);
    end;

  for i:=0 to high(FParams)do
    FProcNameSpace.AddOrFree(TNameSpaceParameter.Create(FParams[i].Name,i,FParams[i].Default,FParams[i].Typ));
end;

destructor TNameSpaceScriptFunction.Destroy;
begin
  FreeAndNil(FBody);
  FreeAndNil(FProcNameSpace);
  inherited;
end;

function TNameSpaceScriptFunction.Dump(const AIndent: integer): ansistring;
begin
  result:=Inherited;
  result:=result+FProcNameSpace.Dump(AIndent+1);
  if FBody<>nil then
    result:=result+FBody.Dump(AIndent+1);
end;

procedure TNameSpaceScriptFunction.Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
var ctx:TContext;
    i:integer;
begin
  ctx:=TContext.Create(AContext,FProcNameSpace,AParams);
  //alloc space for local variables and parameters
  setlength(ctx.FLocalValues,FLocalValueCount+max(length(FParams),AParams.ParamCount));
  //init unspecified default parameters
  for i:=AParams.ParamCount to high(FParams)do ctx.FLocalValues[i]:=FParams[i].Default;
  try
    if Assigned(FBody)then
      FBody.Eval(ctx,AResult);
    AResult:=ctx.ResultValue;
  finally
    ctx.free;
  end;
end;

{ TNameSpace }

constructor TNameSpace.Create(const AName:ansistring);
begin
  FName:=AName;
end;

destructor TNameSpace.Destroy;
var i:integer;
begin
  for i:=FList.FCount-1 downto 0 do
    FList.FItems[i].Free;
  FList.Clear;
  inherited;
end;

procedure TNameSpace.ErrorAlreadyExists(const AName:ansistring);
begin
  NameSpaceError('Name already exists '+toPas(GetFullName+'.'+AName));
end;

procedure TNameSpace.Add(const AEntry:TNameSpaceEntry);
  function cname:string;
  begin
    if AEntry.FBaseClass=nil then result:=''
                             else result:=AEntry.FBaseClass.ClassName+'.';
  end;

var idx:integer;
begin
  if not FList.FindBinary(function(const a:TNamespaceEntry):integer begin result:=cmp(AEntry.fhash,a.fhash)end,idx)then
    FList.Insert(AEntry,idx)
  else
    ErrorAlreadyExists(cname+AEntry.FName);

  AEntry.FNameSpace:=Self;
end;

procedure TNameSpace.AddOrFree(const AEntry:TNameSpaceEntry);
begin
  try
    Add(AEntry);
  except
    AEntry.Free;
    raise;
  end;
end;

function TNameSpace.FindByHash(const AHash: integer): TNameSpaceEntry;
var idx:integer;
begin
  if FList.FindBinary(function(const a:TNamespaceEntry):integer begin result:=cmp(AHash,a.FHash)end,idx)then
    result:=FList.FItems[idx]
  else
    result:=nil;
end;

function TNameSpace.FindByHashReqursive(const AHash: integer): TNameSpaceEntry;
var i:integer;
begin
  if self=nil then exit(nil);
  result:=FindByHash(AHash);
  if result<>nil then exit;
  for i:=nsUses.FCount-1 downto 0 do begin
    result:=nsUses.FItems[i].FindByHash(AHash);
    if result<>nil then exit;
  end;
  result:=FParent.FindByHashReqursive(AHash);
end;

function TNameSpace.FindByName(const AName:AnsiString): TNameSpaceEntry;
begin
  result:=FindByHash(Crc32UC(AName));
end;

function TNameSpace.FindByNameReqursive(const AName: ansistring): TNameSpaceEntry;
begin
  result:=FindByHashReqursive(Crc32UC(AName));
end;

procedure TNameSpace.Delete(const AName:ansistring;const ErrorWhenNotFound:boolean=false);
var idx,h:integer;
begin
  h:=Crc32UC(AName);
  if FList.FindBinary(function(const a:TNamespaceEntry):integer begin result:=cmp(h,a.FHash)end,idx)then begin
    FList.FItems[idx].Free;
    FList.Remove(idx);
  end else begin
    if ErrorWhenNotFound then NameSpaceError('Delete(): Can''t find NameSpaceEntry "'+AName+'"');
  end;
end;

function TNameSpace.GetFullName: AnsiString;
begin
  if Self=nil then result:='' else
  if FParent=nil then result:=FName
                 else result:=FParent.FullName+'.'+FName;
end;

function TNameSpace.WordList: TArray<ansistring>;
var i:integer;
begin with FList do begin
  setlength(result,Count);
  for i:=0 to Count-1 do Result[i]:=FItems[i].FName;
end;end;

procedure TNameSpace.AddConstant(const ADefinition: ansistring; const AValue: variant);
begin
  AddOrFree(TNameSpaceConstant.Create(ADefinition,AValue));
end;

procedure TNameSpace.AddVariable(const ADefinition: ansistring; const AValue: variant);
begin
  if FParent=nil then AddOrFree(TNameSpaceVariable.Create(ADefinition,AValue))
                 else AddOrFree(TNameSpaceLocalVariable.Create(ADefinition,-1));
end;

procedure TNameSpace.AddFunction(const ADefinition:ansistring;const AEval:TEvalFunct;const ALet:TLetProc=nil);
begin
  AddOrFree(TNameSpaceFunction.Create(ADefinition,AEval,ALet));
end;

procedure TNameSpace.AddFunction(const ADefinition:ansistring;const AEval:TEvalCtxFunct;const ALet:TLetCtxProc=nil);
begin
  AddOrFree(TNameSpaceCtxFunction.Create(ADefinition,AEval,ALet));
end;

procedure TNameSpace.AddVectorFunction(const ADefinition:ansistring;const AEval:TEvalFunct;const ALet:TLetProc=nil);
begin
  AddOrFree(TNameSpaceVectorFunction.Create(ADefinition,AEval,ALet));
end;

procedure TNameSpace.AddObjectFunction(const ABaseClass:TClass;const ADefinition:ansistring;const AEval:TEvalObjectFunct;const ALet:TLetObjectProc=nil);
begin
  AddOrFree(TNameSpaceObjectFunction.Create(ABaseClass,ADefinition,AEval,ALet));
end;

procedure TNameSpace.AddDefaultObjectFunction(const ABaseClass:TClass;const ADefinition:ansistring;const AEval:TEvalObjectFunct;const ALet:TLetObjectProc=nil);
var def:ansistring;
    i:integer;
begin
  i:=max(pos('(',ADefinition),pos('[',ADefinition));
  if i<=0 then i:=length(ADefinition)+1;
  def:='__Default'+copy(ADefinition,i,$fff);

  AddObjectFunction(ABaseClass,ADefinition,AEval,ALet);
  AddObjectFunction(ABaseClass,def,AEval,ALet);
end;

procedure TNameSpace.AddClass(const AClass:TClass);
begin
  AddConstant(AClass.ClassName,VClass(AClass));
end;

procedure TNameSpace.AddObjectConstructor(const ABaseClass:TClass;const ADefinition:ansistring;const AConstr:TObjectConstructFunct);
begin
  AddOrFree(TNameSpaceObjectConstructor.Create(ABaseClass,ADefinition,AConstr));
end;

procedure TNameSpace.AddUses(const AUses:TNameSpace);
var i:integer;
begin
  if AUses=nil then exit;
  if not(AUses is TNameSpace)then
    NameSpaceError('TNameSpace.AddUses() TNameSpace expected (instead of '+topas(AUses.ClassName)+')');
  for i:=0 to nsUses.Count-1 do if nsUses.FItems[i]=AUses then
    NameSpaceError('TNameSpace.AddUses() TNameSpace '+topas(AUses.GetFullName)+' already exists in uses list');
  nsUses.Append(AUses);
end;

procedure TNameSpace.AddUses(const AUses:ansistring);
var ns:TNameSpace;
    s:ansistring;
begin
  for s in listSplit(AUses,',')do begin
    ns:=FindRegisteredNameSpaceByName(s);
    if ns=nil then
      NameSpaceError('TNameSpace.AddUses() cannot find namespace '+topas(s));
    AddUses(ns);
  end;
end;

procedure TNameSpace.AddUses(const AUses:array of const);
var i:integer;
begin
  for i:=0 to high(AUses)do case AUses[i].VType of
    vtAnsiString:AddUses(AUses[i].VAnsiString);
    vtUnicodeString:AddUses(AnsiString(AUses[i].VUnicodeString));
    vtObject:AddUses(TNameSpace(AUses[i].VObject));
  else
    NameSpaceError('TNameSpace.AddUses([]) unknown vartype in constlist');
  end;
end;

function TNameSpace.Dump(const AIndent:integer=0):ansistring;
var i:integer;
begin
  result:=Indent('   ',AIndent)+'NameSpace '+FName+#13#10;
  for i:=0 to FList.FCount-1 do
    result:=result+FList.FItems[i].Dump(AIndent+1);
end;

type
  TEnumCaster=class(TNameSpaceEntry)
  private
    FTypeInfo:PTypeInfo;
  public
    constructor create(const ATypeInfo:PTypeInfo);
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
  end;

constructor TEnumCaster.create(const ATypeInfo:PTypeInfo);
var n:ansistring;
begin
  if ATypeInfo.Kind<>tkEnumeration then raise Exception.Create('TEnumCaster.Create() tkEnumeration needed "'+ATypeInfo.Name+'"');
  FTypeInfo:=ATypeInfo;

  //adjust internal name if needed
  n:=FTypeInfo.Name;
  if copy(n,1,1)=':' then
    n:='TEnum'+copy(n,2,$ff);

  inherited Create(n+'(X)');
end;

procedure TEnumCaster.Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  AResult:=VEnum(AParams.EvalParam(AContext,0),FTypeInfo);
end;

type
  TSetCaster=class(TNameSpaceEntry)
  private
    FTypeInfo:PTypeInfo;
    FEnumTypeInfo:PTypeInfo;
  public
    constructor create(const ATypeInfo:PTypeInfo);
    procedure Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);override;
  end;

constructor TSetCaster.create(const ATypeInfo:PTypeInfo);
begin
  if ATypeInfo.Kind<>tkSet then raise Exception.Create('TSetCaster.Create() tkSet needed "'+ATypeInfo.Name+'"');
  FTypeInfo:=ATypeInfo;
  FEnumTypeInfo:=GetTypeData(FTypeInfo).CompType^;
  inherited Create(FTypeInfo.Name+'(X)');
end;

procedure TSetCaster.Eval(var AResult:variant;const AContext:TContext;const AObj:TObject;const AParams:TNodeParamList);
begin
  AResult:=VSetOrdinal(AParams.EvalParam(AContext,0),FEnumTypeInfo);
end;

procedure TNameSpace.AddEnum(const ATypeInfo:PTypeInfo);
var td:PTypeData;
    p:PShortString;
    i:integer;
    n:TNameSpaceEntry;
begin
  if ATypeInfo.Kind<>tkEnumeration then NameSpaceError('AddEnum() tkEnumeration needed instead of '+topas(ATypeInfo.Name));
  td:=GetTypeData(Atypeinfo);
  p:=@td.NameList;
  for i:=td.MinValue to td.MaxValue do begin
    n:=FindByName(p^);
    if n=nil then AddConstant(p^,VEnum(i,ATypeInfo))
             else if n is TNameSpaceConstant then TNameSpaceConstant(n).Value:=VEnum(i,ATypeInfo);
    pInc(p,length(p^)+1);
  end;

  AddOrFree(TEnumCaster.Create(ATypeInfo));
end;

procedure TNameSpace.AddSet(const ATypeInfo:PTypeInfo);
begin
  if ATypeInfo.Kind<>tkSet then NameSpaceError('AddSet() tkSet needed instead of '+topas(ATypeInfo.Name));
  AddEnum(GetTypeData(ATypeInfo).CompType^);
  AddOrFree(TSetCaster.Create(ATypeInfo));
end;

// -----------------------------------------------------------------------------
// Basic operations (upgraded with vector operations)                         //
// -----------------------------------------------------------------------------

procedure vOp_Single(const op:TVarOp;var A:variant);overload;
begin
  case op of
    opNegate:A:=-A;
    opNot:A:=not A;
    opInc:VarInc(A);
    opDec:VarDec(A);
  else raise Exception.Create('het.Parser.vOp() unknown operation ('+tostr(op)+')')end;
end;

procedure vOp_Single(const op:TVarOp;var A:variant;const B:variant);overload;

  procedure DoWithoutFloatOverflow;

    function isInt32(const A:variant):boolean;
    begin
      result:=TVarData(A).vType in[varSmallInt, varInteger, varShortInt,
                                   varByte, varWord, varLongWord];
    end;

  var C:variant;
  begin
    case op of
      opAdd:C:=A+B;
      opSubtract:C:=A-B;
      opMultiply:C:=A*B;
      opAnd:C:=A and B;
      opOr:C:=A or B;
      opXor:C:=A xor B;
    end;
    if isInt32(A)and isInt32(B)and not isInt32(C)then with TVarData(C)do begin
      VType:=varInteger;
      case op of
        opAdd:     VInteger:=TVarData(A).VInteger+TVarData(B).VInteger;
        opSubtract:VInteger:=TVarData(A).VInteger-TVarData(B).VInteger;
        opMultiply:VInteger:=TVarData(A).VInteger*TVarData(B).VInteger;
        opAnd:     VInteger:=TVarData(A).VInteger and TVarData(B).VInteger;
        opOr:      VInteger:=TVarData(A).VInteger or TVarData(B).VInteger;
        opXor:     VInteger:=TVarData(A).VInteger xor TVarData(B).VInteger;
      end;
    end;
    A:=C;//result
  end;
var i64:int64;
begin
  case op of
    opInc:VarInc(A,B);
    opDec:VarDec(A,B);
    opAdd,opSubtract,opMultiply:DoWithoutFloatOverflow;
    opDivide:A:=A/B;
    opIntDivide:A:=A div B;
    opModulus:A:=A mod B;
    opFloatModulus:A:=frac(A/B)*B;
    opPower:A:=power(A,B);
    opAnd,opOr,opXor:DoWithoutFloatOverflow;
    opShiftLeft:A:=A shl B;
    opShiftRight:A:=A shr B;
    opShiftRightSigned:begin i64:=A;A:=sar(i64,B);end;
    opCmpEQ:A:=A=B;
    opCmpNE:A:=A<>B;
    opCmpLT:A:=A<B;
    opCmpLE:A:=A<=B;
    opCmpGT:A:=A>B;
    opCmpGE:A:=A>=B;
  else raise Exception.Create('het.Parser.vOp() unknown operation ('+tostr(op)+')')end;
end;

procedure _vArrayOp_Access(const a:variant;out p:PVariant;out len:Integer);
begin
  if TVarData(a).VType=varArray or varVariant then with VarArrayAsPSafeArray(a)^ do begin
    p:=Data;
    len:=Bounds[0].ElementCount;
  end else begin
    p:=@a;
    len:=1;
  end;
end;

procedure vOp(const Op:TVarOp;var A:variant);overload;
var i,alen:integer;
    pa:PVariant;
begin
  _vArrayOp_Access(a,pa,alen);
  for i:=0 to alen-1 do begin
    vOp_Single(Op,pa^);inc(pa);
  end;
end;

procedure vOp(const Op:TVarOp;var A:variant;const b:variant);overload;
var i,alen,blen:integer;
    pa,pb:PVariant;
begin
  _vArrayOp_Access(a,pa,alen);
  _vArrayOp_Access(b,pb,blen);

  if alen=blen then //vect*vect
    for i:=0 to alen-1 do begin
      vOp_Single(Op,pa^,pb^); inc(pa);inc(pb);end
  else if(blen=1)then //vect*skalar
    for i:=0 to alen-1 do begin
      vOp_Single(Op,pa^,pb^); inc(pa);end
  else if(alen=1)then begin //skalar*vect
    for i:=0 to blen-1 do begin
      vOp_Single(Op,pb^,pa^); inc(pb);end;
    A:=B;
  end else
    raise EVariantInvalidArgError.Create('vArrayOp() ArrayLength mismatch error');
end;

// -----------------------------------------------------------------------------
// Expression tree Nodes                                                      //
// -----------------------------------------------------------------------------

{ TNodeBase }

function TNodeBase.Clone:TNodeBase;
var i:integer;
    sn:TNodeBase;
begin
  result:=TNodeBaseClass(Self.ClassType).Create;
  for i:=0 to SubNodeCount-1 do begin
    sn:=SubNode(i);
    if sn=nil then Result.SetSubNode(i,nil)
              else Result.SetSubNode(i,sn.Clone);
  end;
end;

destructor TNodeBase.Destroy;
begin
  FreeSubNodes;
  inherited;
end;

function TNodeBase.Eval(const AContext: TContext): variant;
begin
  Eval(AContext,result);
end;

procedure TNodeBase.FreeSubNodes;
var i:integer;
begin
  for i:=SubNodeCount-1 downto 0 do SubNode(i).Free;
end;

procedure TNodeBase.Let(const AContext: TContext; const AValue: Variant);
begin
  ExecError('Assignment operation not supported  node:'+topas(ClassName));
end;

procedure TNodeBase.Ref(const AContext:TContext;const AErrorIfCant:boolean;var AResult:variant);
begin
  if AErrorIfCant then ExecError('GetReference operation not supported  node:'+topas(ClassName));
  Eval(AContext,AResult);
end;

function TNodeBase.Ref(const AContext:TContext;const AErrorIfCant:boolean):variant;
begin
  Ref(AContext,AErrorIfCant,Result);
end;

function TNodeBase.RefPtr(const AContext:TContext):PVariant;
var tmp:variant;
begin
  Ref(AContext,false,tmp);
  if VarIsReference(tmp)then result:=VarDereference(tmp)
                        else begin
                          ExecError('Cannot get reference  node:'+topas(ClassName));
                          result:=nil;//nowarn
                        end;
end;

function TNodeBase.RefPtr(const AContext:TContext;var tmp:variant):PVariant;
begin
  Ref(AContext,false,tmp);
  if VarIsReference(tmp)then result:=VarDereference(tmp)
                        else result:=@tmp;
end;

{ TNodeLeaf }

function TNodeLeaf.Dump(const AIndent: integer): ansistring;
begin
  result:=Indent('   ',AIndent)+ansistring(ClassName)+#13#10;
end;

procedure TNodeLeaf.SetSubNode(const n: integer; const ANode: TNodeBase);
begin end;

function TNodeLeaf.SubNode(const n: integer): TNodeBase;
begin result:=nil;end;

function TNodeLeaf.SubNodeCount: integer;
begin result:=0;end;

{ TNodeOp }

class function TNodeOp.Priority:integer;
begin
  result:=0;
end;

{ TNode1Op }

function TNode1Op.Dump(const AIndent: integer): ansistring;
begin
  result:=Indent('   ',AIndent)+ansistring(ClassName)+#13#10;
  if FOp1<>nil then result:=result+FOp1.Dump(AIndent+1) else result:=result+Indent('   ',AIndent+1)+'nil';
end;

procedure TNode1Op.SetSubNode(const n: integer; const ANode: TNodeBase);
begin FOp1:=ANode;end;

function TNode1Op.SubNode(const n: integer): TNodeBase;
begin
  if n=0 then result:=FOp1
         else result:=nil;
  end;

function TNode1Op.SubNodeCount: integer;
begin result:=1;end;

{ TNode2Op }

function TNode2Op.Dump(const AIndent: integer): ansistring;
begin
  result:=Indent('   ',AIndent)+ansistring(ClassName)+#13#10;
  if FOp1<>nil then result:=result+FOp1.Dump(AIndent+1) else result:=result+Indent('   ',AIndent+1)+'nil';
  if FOp2<>nil then result:=result+FOp2.Dump(AIndent+1) else result:=result+Indent('   ',AIndent+1)+'nil';
end;

procedure TNode2Op.SetSubNode(const n: integer; const ANode: TNodeBase);
begin
  if n=0 then FOp1:=ANode else
  if n=1 then FOp2:=ANode;
end;

function TNode2Op.SubNode(const n: integer): TNodeBase;
begin
  if n=0 then result:=FOp1 else
  if n=1 then result:=FOp2
         else result:=nil;
end;

function TNode2Op.SubNodeCount: integer;
begin
  result:=2;
end;

{ TPrioX }

class function TPrio12.Priority: integer;begin result:=12 end;
class function TPrio11.Priority: integer;begin result:=11 end;
class function TPrio10.Priority: integer;begin result:=10 end;
class function TPrio9.Priority: integer;begin result:=9 end;
class function TPrio8.Priority: integer;begin result:=8 end;
class function TPrio7.Priority: integer;begin result:=7 end;
class function TPrio6.Priority: integer;begin result:=6 end;
class function TPrio5.Priority: integer;begin result:=5 end;
class function TPrio4.Priority: integer;begin result:=4 end;
class function TPrio3.Priority: integer;begin result:=3 end;

{ TNodeParamList }

procedure TNodeParamList.Eval(const AContext: TContext; var AResult: variant);
begin
end;

procedure TNodeParamList.EvalParam(const AContext:TContext;var AResult:variant;const idx:integer);
begin
  if(self<>nil)and(idx<FSubNodes.FCount)then FSubNodes.FItems[idx].Eval(AContext,AResult)
                                        else AResult:=Unassigned;
end;

function TNodeParamList.EvalParam(const AContext:TContext;const idx:integer):variant;
begin
  if(self<>nil)and(idx<FSubNodes.FCount)then FSubNodes.FItems[idx].Eval(AContext,Result)
                                        else result:=Unassigned;
end;

function TNodeParamList.ParamCount:integer;
begin
  if(self<>nil)then result:=FSubNodes.FCount
               else result:=0;
end;

procedure TNodeParamList.EnsureParamCount(const ACnt:integer;const msg:AnsiString);
var n:integer;
begin
  if(self=nil)then n:=0
              else n:=FSubNodes.FCount;
  if n<>ACnt then
    if n>ACnt then ExecError('Too many parameters '''+msg+'''')
              else ExecError('Not enough parameters '''+msg+'''');
end;

procedure TNodeParamList.EnsureParamCount(const AMin,AMax:integer;const msg:AnsiString);
var n:integer;
begin
  if(self=nil)then n:=0
              else n:=FSubNodes.FCount;
  if n>AMax then ExecError('Too many parameters '''+msg+'''')else
  if n<AMin then ExecError('Not enough parameters '''+msg+'''');
end;

{ TNodeConstant }

constructor TNodeConstant.Create(const AValue: Variant);
begin
  FValue:=AValue;
end;

function TNodeConstant.Dump(const AIndent: integer): ansistring;
begin
  result:=Indent('   ',AIndent)+ansistring(ClassName)+' '+ansistring(VarTypeAsText(VarType(FValue)))+' '+ToStr(FValue)+' '+#13#10;
end;

function TNodeConstant.Clone:TNodeBase;
begin
  Result:=inherited;
  TNodeConstant(Result).FValue:=FValue;
end;

procedure TNodeConstant.Eval(const AContext: TContext; var AResult: variant);
begin
  AResult:=FValue;
end;

{ TNodeConstantExpr }

constructor TNodeConstantExpr.Create(const AExpr:TNodeBase);
begin
  FOp1:=AExpr;
end;

function TNodeConstantExpr.Dump(const AIndent: integer): ansistring;
begin
  result:=Indent('   ',AIndent)+ansistring(ClassName)+' '+ansistring(VarTypeAsText(VarType(FValue)))+' '+ToStr(FValue)+' '+#13#10+
          FOp1.Dump(AIndent+1);
end;

function TNodeConstantExpr.Clone:TNodeBase;
begin
  Result:=inherited;
end;

procedure TNodeConstantExpr.Eval(const AContext: TContext; var AResult: variant);
begin
  if not FEvaluated then begin
    FOp1.Eval(AContext,AResult);
    FEvaluated:=true;
  end;
  AResult:=FValue;
end;

{ TNodeIdentifier }

constructor TNodeIdentifier.Create(const AName: ansistring);
begin
  IdName:=AName;
end;

function TNodeIdentifier.Dump(const AIndent: integer): ansistring;
begin
  result:=Indent('   ',AIndent)+ansistring(ClassName)+' '+FIdName+' '+ansistring(inttohex(FIdHash,8))+#13#10;
end;

function TNodeIdentifier.Clone:TNodeBase;
begin
  Result:=Inherited;
  TNodeIdentifier(Result).IdName:=IdName;
end;

procedure TNodeIdentifier.SetIdName(const Value: ansistring);
begin
  FIdName:=Value;
  FIdHash:=Crc32UC(FIdName);
end;

procedure TNodeIdentifier.Eval(const AContext: TContext; var AResult: variant);
begin
  if FNameSpaceEntry=nil then
    FNameSpaceEntry:=AContext.AcquireNameSpaceEntry(FIdName,false,0);
  FNameSpaceEntry.Eval(AResult,AContext,nil,nil);

  //Automatic dereference (Experimental!!!!)
{ DONE : megoldani az automatikus var^ -t }
{  if VarIsReference(AResult) then
    AResult:=VarDereference(AResult)^;}
end;

procedure TNodeIdentifier.Let(const AContext: TContext; const AValue: Variant);
begin
  if FNameSpaceEntry=nil then
    FNameSpaceEntry:=AContext.AcquireNameSpaceEntry(FIdName,false,0);
  FNameSpaceEntry.Let(AValue,AContext,nil,nil);
end;

procedure TNodeIdentifier.Ref(const AContext:TContext;const AErrorIfCant:boolean;var AResult:variant);
begin
  if FNameSpaceEntry=nil then
    FNameSpaceEntry:=AContext.AcquireNameSpaceEntry(FIdName,false,0);
  FNameSpaceEntry.Ref(AResult,AContext,nil,nil,AErrorIfCant);
end;

{ TNode_Field }

procedure TNode_Field.UpdateNSE_GetSelfObj(const AContext:TContext;out ASelfObj:TObject;var tmp:variant);
var r:Variant;
begin
  ASelfObj:=nil;//nil even if exception
  r:=FOp1.Ref(AContext,false);
  if VarIsReference(r)then ASelfObj:=VarAsObjectOrInvoker(VarDereference(r)^)
                      else ASelfObj:=VarAsObjectOrInvoker(r);//0 param funct

  if ASelfObj=nil then ExecError('Cannot access '+topas('NIL.'+IdentifierName(FOp2)));
  if(FNameSpaceEntry=nil)or not FNameSpaceEntry.ObjectSupported(ASelfObj)then
    FNameSpaceEntry:=AContext.AcquireNameSpaceEntry(IdentifierName(FOp2),false,0,ASelfObj);
end;

procedure TNode_Field.Eval(const AContext: TContext; var AResult: variant);
var o:TObject;tmp:Variant;
begin
  try
    UpdateNSE_GetSelfObj(AContext,o,tmp);
    FNameSpaceEntry.Eval(AResult,AContext,o,nil);
  finally
    FreeVariantInvoker(o);
  end;
end;

procedure TNode_Field.Let(const AContext: TContext; const AValue: Variant);
var o:TObject;tmp:variant;
begin
  try
    UpdateNSE_GetSelfObj(AContext,o,tmp);
    FNameSpaceEntry.Let(AValue,AContext,o,nil);
  finally
    FreeVariantInvoker(o);
  end;
end;

procedure TNode_FIeld.Ref(const AContext:TContext;const AErrorIfCant:boolean;var AResult:variant);
var o:TObject;tmp:variant;
begin
  try
    UpdateNSE_GetSelfObj(AContext,o,tmp);
    FNameSpaceEntry.Ref(AResult,AContext,o,nil,AErrorIfCant);
  finally
    FreeVariantInvoker(o);
  end;
end;

{ TNode_Funct }

procedure TNode_Funct.UpdateNSE_GetSelfObj(const AContext:TContext;out ASelfObj:TObject);
begin
  ASelfObj:=nil;//nil even if exception
  if IsIdentifier(FOp1)then begin //funct()
    if FNameSpaceEntry=nil then //ez valamiert kimaradt (a cacheolas)
      FNameSpaceEntry:=AContext.AcquireNameSpaceEntry(IdentifierName(Fop1),false,FOp2.SubNodeCount);
  end else if FOp1 is TNode_Field then begin //obj.funct()
    ASelfObj:=VarAsObjectOrInvoker(TNode_Field(FOp1).FOp1.Eval(AContext));
    if ASelfObj=nil then
      ExecError('Cannot access '+topas('NIL.'+IdentifierName(TNode_Field(Fop1).FOp2)+'()'));
    if(FNameSpaceEntry=nil)or not FNameSpaceEntry.ObjectSupported(ASelfObj)then
      FNameSpaceEntry:=AContext.AcquireNameSpaceEntry(IdentifierName(TNode_Field(Fop1).FOp2),false,FOp2.SubNodeCount,ASelfObj);
  end else begin  //obj.Default()
    ASelfObj:=VarAsObjectOrInvoker(FOp1.Eval(AContext));
    if ASelfObj=nil then
      ExecError('Cannot access ''NIL()''');
    if(FNameSpaceEntry=nil)or not FNameSpaceEntry.ObjectSupported(ASelfObj)then
      FNameSpaceEntry:=AContext.AcquireNameSpaceEntry('__Default',false,FOp2.SubNodeCount,ASelfObj);
  end;
end;

procedure TNode_Funct.Eval(const AContext: TContext; var AResult: variant);
var o:TObject;
begin
  try
    UpdateNSE_GetSelfObj(AContext,o);
    FNameSpaceEntry.Eval(AResult,AContext,o,FOp2 as TNodeParamList);
  finally
    FreeVariantInvoker(o);
  end;
end;

procedure TNode_Funct.Let(const AContext:TContext;const AValue:Variant);
var o:TObject;
begin
  try
    UpdateNSE_GetSelfObj(AContext,o);
    FNameSpaceEntry.Let(AValue,AContext,o,FOp2 as TNodeParamList);
  finally
    FreeVariantInvoker(o);
  end;
end;

{ TNode_Index }

procedure TNode_Index.UpdateNSE_GetSelfObj(const AContext:TContext;out ASelfObj:TObject);
var tmp:Variant;
begin
  ASelfObj:=nil;
  if IsIdentifier(FOp1)then begin  // funct[]
    if FNameSpaceEntry=nil then
      FNameSpaceEntry:=AContext.AcquireNameSpaceEntry(IdentifierName(Fop1),true,FOp2.SubNodeCount);
  end else if FOp1 is TNode_Field then begin //obj.funct[]
    ASelfObj:=VarAsObjectOrInvoker(TNode_Field(FOp1).FOp1.RefPtr(AContext,tmp)^);
    if ASelfObj=nil then
      ExecError('Cannot access '+topas('NIL.'+IdentifierName(TNode_Field(Fop1).FOp2)+'[]'));
    if(FNameSpaceEntry=nil)or not FNameSpaceEntry.ObjectSupported(ASelfObj)then
      FNameSpaceEntry:=AContext.AcquireNameSpaceEntry(IdentifierName(TNode_Field(Fop1).FOp2),true,FOp2.SubNodeCount,ASelfObj);
  end;
end;

procedure TNode_Index.Eval(const AContext: TContext; var AResult: variant);

  procedure MyVarArrayGetDyn(var v:variant);
  var params:TIntegerArray;
      i:integer;
      o:TObject;
  begin
    if VarIsObject(v) then begin
      o:=VarAsObject(V);
      if o=nil then
        ExecError('Cannot access ''NIL[]''');
      try
        if(FNameSpaceEntry2=nil)or not(FNameSpaceEntry2.ObjectSupported(o))then
          FNameSpaceEntry2:=AContext.AcquireNameSpaceEntry('__Default',true,TNodeParamList(FOp2).ParamCount,o);
        FNameSpaceEntry2.Eval(AResult,AContext,o,TNodeParamList(FOp2));
      finally
        FreeVariantInvoker(o);
      end;
    end else
      with FOp2 as TNodeParamList do begin
        if ParamCount=1 then begin
          i:=FSubNodes.FItems[0].Eval(AContext);
          AResult:=VarArrayGetDyn(V,i);
        end else begin
          setlength(Params,ParamCount);
          for i:=0 to ParamCount-1 do
            Params[i]:=FSubNodes.FItems[i].Eval(AContext);
          AResult:=VarArrayGetDyn(V,params);
        end;
      end;
  end;

var o:TObject;
    tmp:Variant;
begin
  try
    UpdateNSE_GetSelfObj(AContext,o);

    if(FNameSpaceEntry=nil)then
      MyVarArrayGetDyn(FOp1.RefPtr(AContext,tmp)^)
    else if FNameSpaceEntry.IsIndex then begin
      FNameSpaceEntry.Eval(AResult,AContext,o,FOp2 as TNodeParamList)
    end else
      if o=nil then begin
        MyVarArrayGetDyn(FOp1.RefPtr(AContext,tmp)^)
      end else begin
        FNameSpaceEntry.Eval(AResult,AContext,o,nil);
        MyVarArrayGetDyn(AResult);
      end;

  finally
    FreeVariantInvoker(o);
  end;
end;

procedure TNode_Index.Let(const AContext:TContext;const AValue:Variant);

  procedure MyVarArraySetDyn(var v:variant);
  var params:TIntegerArray;
      i:integer;
      o:TObject;
  begin
    if VarIsObject(v) then begin
      o:=VarAsObject(V);
      if o=nil then
        ExecError('Cannot access ''NIL[]''');
      try
        if(FNameSpaceEntry2=nil)or not(FNameSpaceEntry2.ObjectSupported(o))then
          FNameSpaceEntry2:=AContext.AcquireNameSpaceEntry('__Default',true,TNodeParamList(FOp2).ParamCount,o);
        FNameSpaceEntry2.Let(AValue,AContext,o,TNodeParamList(FOp2));
      finally
        FreeVariantInvoker(o);
      end;
    end else
      with FOp2 as TNodeParamList do begin
        if ParamCount=1 then begin
          i:=FSubNodes.FItems[0].Eval(AContext);
          VarArraySetDyn(V,i,AValue);
        end else begin
          setlength(Params,ParamCount);
          for i:=0 to ParamCount-1 do
            Params[i]:=FSubNodes.FItems[i].Eval(AContext);
          VarArraySetDyn(V,params,AValue);
        end;
      end;
  end;

var o:TObject;
    tmp:variant;
begin
  try
    UpdateNSE_GetSelfObj(AContext,o);

    if(FNameSpaceEntry=nil)then begin
      FOp1.Ref(AContext,false,tmp);
      MyVarArraySetDyn(VarDereference(tmp)^);
      if not VarIsReference(tmp) then
        FOp1.Let(AContext,tmp);
    end else if FNameSpaceEntry.IsIndex then begin
      if FNameSpaceEntry is TNameSpaceObjectFunction then begin
        FNameSpaceEntry.Let(AValue,AContext,o,FOp2 as TNodeParamList);
      end else begin
        FNameSpaceEntry.Eval(tmp,AContext,o,FOp2 as TNodeParamList);
        MyVarArraySetDyn(tmp);
        FNameSpaceEntry.Let(tmp,AContext,o,FOp2 as TNodeParamList);
      end;
    end else
      if o=nil then begin
        FOp1.Ref(AContext,false,tmp);
        MyVarArraySetDyn(VarDereference(tmp)^);
        if not VarIsReference(tmp) then
          FOp1.Let(AContext,tmp);
      end else begin
        FNameSpaceEntry.Eval(tmp,AContext,o,nil);
        MyVarArraySetDyn(tmp);
        FNameSpaceEntry.Let(tmp,AContext,o,nil);
      end;

  finally
    FreeVariantInvoker(o);
  end;
end;

procedure TNode_Index.Ref(const AContext:TContext;const AErrorIfCant:boolean;var AResult:variant);

  procedure MyVarArrayRefDyn(var v:variant);
  var params:TIntegerArray;
      i:integer;
  begin
    if VarIsObject(v) then begin
      ExecError('Cannot get reference of indexed object function');
    end else
      with FOp2 as TNodeParamList do begin
        if ParamCount=1 then begin
          i:=FSubNodes.FItems[0].Eval(AContext);
          AResult:=VReference(VarArrayAccess(V,i)^);
        end else begin
          setlength(Params,ParamCount);
          for i:=0 to ParamCount-1 do
            Params[i]:=FSubNodes.FItems[i].Eval(AContext);
          AResult:=VReference(VarArrayAccess(V,params)^);
        end;
      end;
  end;

var o:TObject;
    tmp:variant;
begin
  try
    UpdateNSE_GetSelfObj(AContext,o);

    if(FNameSpaceEntry=nil)then begin
      FOp1.Ref(AContext,true,tmp);
      MyVarArrayRefDyn(VarDereference(tmp)^);
    end else if FNameSpaceEntry.IsIndex then begin
      if AErrorIfCant then
        ExecError('Cannot get reference of indexed function');

      Eval(AContext,AResult);
      exit;
    end else begin
      if AErrorIfCant then
        ExecError('Cannot get reference of function');

      Eval(AContext,AResult);
      exit;
    end;
    //!!!!!!!!  Nagy kaosz ez itt, de megy... Kesobb ujra kell irni 0-rol

  finally
    FreeVariantInvoker(o);
  end;
end;

{ TNodeNop }

procedure TNodeNop.Eval(const AContext: TContext; var AResult: variant);
begin
end;

{ TNodePlus }

procedure TNodePlus.Eval(const AContext: TContext; var AResult: variant);
begin FOp1.Eval(AContext,AResult);end;

{ TNodeMinus }

procedure TNodeMinus.Eval(const AContext: TContext; var AResult: variant);
begin AResult:=FOp1.Eval(AContext);vOp(opNegate,AResult)end;

{ TNodeNot }

procedure TNodeNot.Eval(const AContext: TContext; var AResult: variant);
begin AResult:=FOp1.Eval(AContext);vOp(OpNot,AResult)end;

{ TNodeFractional }

procedure TNodeFactorial.Eval(const AContext: TContext; var AResult: variant);
var i:integer;r:double;
begin
  FOp1.Eval(AContext,AResult);
  if AResult<=1 then begin AResult:=1;exit;end;
  r:=1;for i:=2 to AResult do r:=r*i;
  AResult:=r;
end;

{ TNodeReference }

procedure TNodeReference.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Ref(AContext,True,AResult);
end;

{ TNodeIndirect }

procedure TNodeIndirect.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if VarIsReference(AResult) then AResult:=VarDereference(AResult)^
                             else ExecError(ClassName+'.Eval() Reference type needed for indirection');
end;

procedure TNodeIndirect.Ref(const AContext:TContext;const AErrorIfCant:boolean;var AResult:variant);
begin
  FOp1.Eval(AContext,AResult);
  if VarIsReference(AResult) then
                             else ExecError(ClassName+'.Ref() Reference type needed for indirection');
end;

{ TNodeInc }

procedure TNodeInc.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  vOp(opInc,AResult);
  FOp1.Let(AContext,AResult);
end;

{ TNodeDec }

procedure TNodeDec.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  vOp(opDec,AResult);
  FOp1.Let(AContext,AResult);
end;

{ TNodePostInc }

procedure TNodePostInc.Eval(const AContext: TContext; var AResult: variant);
var tmp:Variant;
begin
  FOp1.Eval(AContext,AResult);
  with AContext do if BlockPostfixAssignments then begin //while, case, if conditions
    PendingPostfixOperations.Append(self);
  end else begin
    tmp:=AResult;
    vOp(OpInc,tmp);
    FOp1.Let(AContext,tmp);
  end;
end;

procedure TNodePostInc.PostfixFinalize(const AContext: TContext);
var tmp:Variant;
begin
  FOp1.Eval(AContext,tmp);
  vOp(OpInc,tmp);
  FOp1.Let(AContext,tmp);
end;

{ TNodePostDec }

procedure TNodePostDec.Eval(const AContext: TContext; var AResult: variant);
var tmp:Variant;
begin
  FOp1.Eval(AContext,AResult);
  with AContext do if BlockPostfixAssignments then begin //while, case, if conditions
    PendingPostfixOperations.Append(self);
  end else begin
    tmp:=AResult;
    vOp(OpDec,tmp);
    FOp1.Let(AContext,tmp);
  end;
end;

procedure TNodePostDec.PostfixFinalize(const AContext: TContext);
var tmp:Variant;
begin
  FOp1.Eval(AContext,tmp);
  vOp(OpDec,tmp);
  FOp1.Let(AContext,tmp);
end;

{ TNodeNamedVariant }

procedure TNodeNamedVariant.Eval(const AContext: TContext;var AResult: variant);
begin
  if not (FOp1 is TNodeIdentifier)then
    ExecError('NamedVariant left side operator must be an identifier');
  AResult:=VNamed(IdentifierName(FOp1),FOp2.Eval(AContext));
end;

{ TNodeNullCoalescing }

procedure TNodeNullCoalescing.Eval(const AContext: TContext;var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if VarIsNull(AResult) then
     FOp2.Eval(AContext,AResult);
end;

{ TNodeZeroCoalescing }

procedure TNodeZeroCoalescing.Eval(const AContext: TContext;var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if OptVarIsZero(AResult) then
    FOp2.Eval(AContext,AResult);
end;

{ TNodeIs }

procedure TNodeIs.Eval(const AContext: TContext;var AResult: variant);
var tmp:Variant;
begin
  FOp1.Eval(AContext,AResult);
  FOp2.Eval(AContext,tmp);

  if varIsNull(tmp)then AResult:=varIsNull(AResult)
  else if varIsEmpty(tmp)then AResult:=varIsEmpty(AResult)
  else if VarIsObject(AResult)and VarIsClass(tmp)then begin
    if VarIsNil(AResult)then AResult:=false
                        else AResult:=VarAsObject(AResult)is VarAsClass(tmp);
  end else
    ExecError('Invalid combination of operands in is_operation.');

  if invert then AResult:=not AResult;
  
end;

{ TNodePower }

procedure TNodePower.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if not OptVarIsZero(AResult) then
    vOp(OpPower,AResult,FOp2.Eval(AContext));
end;

{ TNodeMul }

procedure TNodeMul.Eval(const AContext: TContext; var AResult: variant);
{ //Str multiply (concat)
  if VarIsStr(AResult)then begin//string mul, nem jó, mert jelenleg str-bol intbe convertal magatol
    FOp2.Eval(AContext,tmp);
    AResult:=StrMul(AnsiString(AResult),integer(tmp));
    exit;
  end;}
{ //opt. double
 if(TVarData(AResult).VType=varDouble)and(TVarData(tmp).VType=varDouble)then
    TVarData(AResult).vDouble:=TVarData(AResult).vDouble*TVarData(tmp).vDouble
  else
    AResult:=AResult*tmp;}
begin
  FOp1.Eval(AContext,AResult);

  if VarIsSet(AResult)then begin
    if VarSetIsEmpty(AResult)then exit;
  end else
    if OptVarIsZero(AResult) then exit;

  vOp(opMultiply,AResult,FOp2.Eval(AContext));
end;

procedure TNodeMul.Let(const AContext: TContext; const AValue: variant);
var v:Variant;
begin
  v:=AValue;
  if not OptVarIsZero(v)then
    vOp(opDivide,v,FOp2.Eval(AContext));
  FOp1.Let(AContext,v);
end;

{ TNodeDiv }

procedure TNodeDiv.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if not OptVarIsZero(AResult) then
    vOp(opDivide,AResult,FOp2.Eval(AContext));
end;

procedure TNodeDiv.Let(const AContext: TContext; const AValue: variant);
var v:Variant;
begin
  v:=AValue;
  if not OptVarIsZero(v)then
    vOp(opMultiply,v,FOp2.Eval(AContext));
  FOp1.Let(AContext,v);
end;

{ TNodeIDiv }

procedure TNodeIDiv.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if not OptVarIsZero(AResult) then
    vOp(opIntDivide,AResult,FOp2.Eval(AContext));
end;

procedure TNodeIDiv.Let(const AContext: TContext; const AValue: variant);
var v:Variant;
begin
  v:=AValue;
  if not OptVarIsZero(v)then
    vOp(opMultiply,v,FOp2.Eval(AContext));
  FOp1.Let(AContext,v);
end;

{ TNodeMod }

procedure TNodeMod.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if not OptVarIsZero(AResult) then
    vOp(opFloatModulus,AResult,FOp2.Eval(AContext));
end;

{ TNodeIMod }

procedure TNodeIMod.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if not OptVarIsZero(AResult) then
    vOp(opModulus,AResult,FOp2.Eval(AContext));
end;

{ TNodeAnd }

procedure TNodeAnd.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if VarIsSet(AResult)then begin
    if VarSetIsEmpty(AResult) then exit;
  end else
    if OptVarIsZero(AResult)then exit;
  vOp(opAnd,AResult,FOp2.Eval(AContext));
end;

{ TNodeShl }

procedure TNodeShl.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if OptVarIsZero(AResult) then exit;
  vOp(opShiftLeft,AResult,FOp2.Eval(AContext));
end;

{ TNodeShr }

procedure TNodeShr.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if OptVarIsZero(AResult) then exit;
  vOp(opShiftRight,AResult,FOp2.Eval(AContext));
end;

{ TNodeSal }

procedure TNodeSal.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if OptVarIsZero(AResult) then exit;
  vOp(opShiftLeft,AResult,FOp2.Eval(AContext));
end;

{ TNodeSar }

procedure TNodeSar.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if OptVarIsZero(AResult) then exit;
  vOp(opShiftRightSigned,AResult,FOp2.Eval(AContext));
end;

{ TNodeAdd }

procedure TNodeAdd.Eval(const AContext: TContext; var AResult: variant);
begin
  AResult:=FOp1.Eval(AContext);
  vOp(OpAdd,AResult,FOp2.Eval(AContext));
end;

procedure TNodeAdd.Let(const AContext: TContext; const AValue: variant);
var v:Variant;
begin
  v:=AValue;
  vOp(opSubtract,v,FOp2.Eval(AContext));
  FOp1.Let(AContext,v);
end;

{ TNodeSub }

procedure TNodeSub.Eval(const AContext: TContext; var AResult: variant);
begin
  AResult:=FOp1.Eval(AContext);
  vOp(opSubtract,AResult,FOp2.Eval(AContext));
end;

procedure TNodeSub.Let(const AContext: TContext; const AValue: variant);
var v:variant;
begin
  v:=AValue;
  vOp(OpAdd,v,FOp2.Eval(AContext));
  FOp1.Let(AContext,v);
end;

{ TNodeOr }

procedure TNodeOr.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if VarIsType(AResult,varBoolean)then
    if AResult then
      exit;
  vOp(OpOr,AResult,FOp2.Eval(AContext));
end;

{ TNodeXor }

procedure TNodeXor.Eval(const AContext: TContext; var AResult: variant);
begin
  AResult:=FOp1.Eval(AContext);
  vOp(OpXor,AResult,FOp2.Eval(AContext));
end;

{ TNodeConcat }

procedure TNodeConcat.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if VarIsArray(AResult)then VarArrayConcat(AResult,FOp2.Eval(AContext))
                        else AResult:=ToStr(AResult)+ToStr(FOp2.Eval(AContext));
end;

{ TNodeLike }

procedure TNodeLike.Eval(const AContext: TContext; var AResult: variant);
var tmp:variant;
begin
  if FOp2 is TNodeSetConstruct then begin
    AResult:=TNodeSetConstruct(FOp2).EvalIsWild(ToStr(FOp1.Eval(AContext)),AContext)
  end else begin
    tmp:=FOp2.Eval(AContext);
    if VarIsSet(tmp)then
      AResult:=VarAsSetArray(tmp).IsWild(ToStr(FOp1.Eval(AContext)))
    else
      AResult:=IsWild2(ToStr(FOp2.Eval(AContext)),ToStr(FOp1.Eval(AContext)),true);
  end;
end;

{ TNodeNotLike }

procedure TNodeNotLike.Eval(const AContext: TContext; var AResult: variant);
begin
  inherited Eval(AContext,AResult);
  AResult:=not AResult;
end;

{ TNodeIn }

procedure TNodeIn.Eval(const AContext: TContext; var AResult: variant);
var c:cardinal;
    tmp,val:variant;
    i:integer;
begin
  if FOp2 is TNodeSetConstruct then begin//optimized case. using nodesetConstruct structure instead of setvariant
    AResult:=TNodeSetConstruct(FOp2).EvalContains(FOp1.Eval(AContext),AContext);
  end else if FOp2 is TNodeArrayConstruct then begin//optimized array
    FOp1.Eval(AContext,tmp);
    for i:=0 to TNodeArrayConstruct(FOp2).SubNodeCount-1 do
      if tmp=TNodeArrayConstruct(FOp2).SubNode(i).Eval(AContext)then begin AResult:=true;exit end;
    AResult:=false;
  end else begin//unoptimized using variants
    FOp2.Eval(AContext,tmp);
    if VarIsSet(tmp)then AResult:=VarAsSetArray(tmp).Contains(FOp1.Eval(AContext)) //for setVariant
    else if VarIsOrdinal(tmp)then begin//bit test: a in b -> a and b = a
      c:=FOp1.Eval(AContext);
      AResult:=(c and cardinal(tmp))=c;
    end else if VarIsArray(tmp) then begin//array
      FOp1.Eval(AContext,val);
      for i:=varArrayLowBound(tmp,1)to varArrayHighBound(tmp,1)do
        if val=tmp[i]then begin AResult:=true;exit;end;
      AResult:=false;
    end else//str
      AResult:=(het.Utils.Pos(ansistring(FOp1.Eval(AContext)),ansistring(tmp),[poIgnoreCase])>0);//for a in b -> pos(a,b)>0 ignorecase
  end;
end;

{TNodeNotIn}

procedure TNodeNotIn.Eval(const AContext: TContext; var AResult: variant);
begin
  inherited Eval(AContext,AResult);
  AResult:=not AResult;
end;

{ TNodeRelation }

function TNodeRelation.RelationF(const a,b:variant):boolean;
var t:variant;
begin
  t:=a;Relation(t,b);
  result:=t;
end;

function TNodeRelation.EvalReturnRightOp(const AContext: TContext; var AResult: Variant):boolean;
var left:Variant;
begin
  if FOp1 is TNodeRelation then begin
    Result:=(FOp1 as TNodeRelation).EvalReturnRightOp(AContext,left);
    if result then begin
      FOp2.Eval(AContext,AResult);
      result:=RelationF(left,AResult);
    end;
  end else begin
    FOp1.Eval(AContext,left);
    FOp2.Eval(AContext,AResult);
    result:=RelationF(left,AResult);
  end;
end;

procedure TNodeRelation.Eval(const AContext: TContext; var AResult: Variant);
var ct:TCustomVariantType;
    op:TVarOp;
begin
  if FOp1 is TNodeRelation then begin
    //dulpa relacio AND muvelettel
    AResult:=(FOp1 as TNodeRelation).EvalReturnRightOp(AContext,AResult)and RelationF(AResult,FOp2.Eval(AContext));
  end else begin
    FOp1.Eval(AContext,AResult);
    //specialis relaciokezeles pl az SSE tipushoz
    if FindCustomVariantType(TVarData(AResult).VType,ct)and(ct is TCustomVariantTypeSpecialRelation)then begin
      if self is TNodeEqual then op:=opCmpEQ else
      if self is TNodeNotEqual then op:=opCmpNE else
      if self is TNodeGreater then op:=opCmpGT else
      if self is TNodeGreaterEqual then op:=opCmpGE else
      if self is TNodeLess then op:=opCmpLT else
{      if self is TNodeLessEqual then }op:=opCmpLE;

      TCustomVariantTypeSpecialRelation(ct).RelationOp(AResult,FOp2.Eval(AContext),op);
    end else
      Relation(AResult,FOp2.Eval(AContext));
  end;
end;


{ TNodeEqual }

procedure TNodeEqual.Relation(var a:variant;const b:variant);
begin
  vOp(opCmpEQ,a,b);
end;

{ TNodeNotEqual }

procedure TNodeNotEqual.Relation(var a:variant;const b:variant);
begin
  vOp(opCmpNE,a,b);
end;

{ TNodeGreater }

procedure TNodeGreater.Relation(var a:variant;const b:variant);
begin
  vOp(opCmpGT,a,b);
end;

{ TNodeGreaterEqual }

procedure TNodeGreaterEqual.Relation(var a:variant;const b:variant);
begin
  vOp(opCmpGE,a,b);
end;

{ TNodeLess }

procedure TNodeLess.Relation(var a:variant;const b:variant);
begin
  vOp(opCmpLT,a,b);
end;

{ TNodeLessEqual }

procedure TNodeLessEqual.Relation(var a:variant;const b:variant);
begin
  vOp(opCmpLE,a,b);
end;

{ TNodeTenary }

procedure TNodeTenary.Eval(const AContext: TContext; var AResult: variant);
var q,a,b:variant;
    pq,pr,pa,pb:pvariant;
    qlen,rlen,alen,blen,i:integer;
begin
  FOp1.Eval(AContext,q);
  _vArrayOp_Access(q,pq,qlen);
  if qlen>1 then begin //paralell
    TNodeTenaryChoices(FOp2).FOp1.Eval(AContext,a); _vArrayOp_Access(a,pa,alen);
    TNodeTenaryChoices(FOp2).FOp2.Eval(AContext,b); _vArrayOp_Access(b,pb,blen);
    AResult:=VarArrayCreate([0,qlen-1],varVariant); _vArrayOp_Access(AResult,pr,rlen);
    if not((qlen=alen)or(alen=1))or not((qlen=blen)or(blen=1))then
      raise EVariantInvalidArgError.Create('vArrayOp() ArrayLength mismatch error');
    for i:=0 to qlen-1 do begin
      if pq^ then pr^:=pa^ else pr^:=pb^;
      inc(pq);inc(pr);inc(pa);inc(pb);
    end;
  end else begin
    if q then TNodeTenaryChoices(FOp2).FOp1.Eval(AContext,AResult)
         else TNodeTenaryChoices(FOp2).FOp2.Eval(AContext,AResult);
  end;
end;

{ TNodeTenaryChoices }

procedure TNodeTenaryChoices.Eval(const AContext: TContext; var AResult: variant);
begin
  raise Exception.Create('TNodeTenaryChoices.Eval() should not be called');
end;

{ TNodeLet }

procedure TNodeLet.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp2.Eval(AContext,AResult);
  FOp1.Let(AContext,AResult);
end;

{ TNodeLetAdd }

procedure TNodeLetAdd.Eval(const AContext: TContext; var AResult: variant);
begin
  AResult:=FOp1.Eval(AContext);
  vOp(OpAdd,AResult,FOp2.Eval(AContext));
  FOp1.Let(AContext,AResult);
end;

{ TNodeLetSub }

procedure TNodeLetSub.Eval(const AContext: TContext; var AResult: variant);
begin
  AResult:=FOp1.Eval(AContext);
  vOp(opSubtract,AResult,FOp2.Eval(AContext));
  FOp1.Let(AContext,AResult);
end;

{ TNodeLetMul }

procedure TNodeLetMul.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if not OptVarIsZero(AResult) then
    vOp(opMultiply,AResult,FOp2.Eval(AContext));
  FOp1.Let(AContext,AResult);
end;

{ TNodeLetDiv }

procedure TNodeLetDiv.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if not OptVarIsZero(AResult) then
    vOp(opDivide,AResult,FOp2.Eval(AContext));
  FOp1.Let(AContext,AResult);
end;

{ TNodeLetPower }

procedure TNodeLetPower.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if not OptVarIsZero(AResult) then
    vOp(opPower,AResult,FOp2.Eval(AContext));
  FOp1.Let(AContext,AResult);
end;

{ TNodeLetMod }

procedure TNodeLetMod.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if not OptVarIsZero(AResult) then
    vOp(opFloatModulus,AResult,FOp2.Eval(AContext));
  FOp1.Let(AContext,AResult);
end;

{ TNodeLetConcat }

procedure TNodeLetConcat.Eval(const AContext: TContext; var AResult: variant);
begin
  FOp1.Eval(AContext,AResult);
  if VarIsArray(AResult)then VarArrayConcat(AResult,FOp2.Eval(AContext))
                        else AResult:=ToStr(AResult)+ToStr(FOp2.Eval(AContext));
  FOp1.Let(AContext,AResult);
end;

{ TNodeLambda }

procedure TNodeLambda.Eval(const AContext: TContext; var AResult: variant);
begin
  AResult:='Lambda expressions not supported yet';
end;

{ TNodeSetConstruct }

procedure TNodeSetConstruct.Eval(const AContext: TContext; var AResult: variant);
var i:integer;
    sn:TNodeBase;
begin
  AResult:=VSet;
  with VarAsSetArray(AResult) do
    for i:=0 to SubNodeCount-1 do begin
      sn:=SubNode(i);
      if sn is TNodeRange then
        AddRange(TNodeRange(sn).FOp1.Eval(AContext),TNodeRange(sn).FOp2.Eval(AContext))
      else
        AddSingle(sn.Eval(AContext));
    end;
end;

function TNodeSetConstruct.EvalContains(const AValue:variant;const AContext:TContext):boolean;
var i:integer;
    n:TNodeBase;
begin
  if SubNodeCount=0 then exit(false);
  for i:=0 to SubNodeCount-1 do begin
    n:=SubNode(i);
    if n is TNodeRange then begin
      if(AValue>=TNodeRange(n).FOp1.Eval(AContext))and(AValue<=TNodeRange(n).FOp2.Eval(AContext))then exit(true);
    end else begin
      if AValue=n.Eval(AContext)then exit(true);
    end;
  end;
  result:=false;
end;

function TNodeSetConstruct.EvalIsWild(const AValue:ansistring;const AContext:TContext):boolean;
var i:integer;
    n:TNodeBase;
begin
  if SubNodeCount=0 then exit(false);
  for i:=0 to SubNodeCount-1 do begin
    n:=SubNode(i);
    if n is TNodeRange then begin
      if(AValue>=TNodeRange(n).FOp1.Eval(AContext))and(AValue<=TNodeRange(n).FOp2.Eval(AContext))then exit(true);
    end else begin
      if IsWild2(n.Eval(AContext),AValue)then exit(true);
    end;
  end;
  result:=false;
end;

{ TNodeRange }

procedure TNodeRange.Eval(const AContext: TContext; var AResult: variant);
begin
  AResult:=null;exit;
  AResult:=VSetRange(FOp1.Eval(AContext),FOp2.Eval(AContext));
end;

{ TNodeArrayConstruct }

procedure TNodeArrayConstruct.Eval(const AContext: TContext; var AResult: variant);
var i:integer;
begin
  AResult:=VarArrayCreate([0,SubNodeCount-1],varVariant);
  for i:=0 to SubNodeCount-1 do
    AResult[i]:=SubNode(i).Eval(AContext);
end;

procedure TNodeArrayConstruct.Let(const AContext: TContext; const AValue: variant);
var i:integer;
    sn:TNodeBase;
    psrc:PVariant;
    dst:TNodeBase;
begin
  for i:=0 to subNodeCount-1 do begin
    sn:=SubNode(i);
    if sn=nil then continue;
    if sn is TNodeNamedVariant then begin
      dst:=TNodeNamedVariant(sn).FOp2;
      psrc:=VarArrayAccessNamed(AValue,TNodeIdentifier(TNodeNamedVariant(sn).FOp1).FIdName);
    end else begin
      dst:=sn;
      psrc:=VarArrayAccess(AValue,i);
    end;

    if dst=nil then Continue;
    if(dst is TNodeIdentifier)and(cmp(TNodeIdentifier(dst).FIdName,'null')=0)then Continue;

    if psrc=nil then dst.Let(AContext,varNull)
                else dst.Let(AContext,psrc^);
  end;
end;

{ TNodeSequence }

destructor TNodeSequence.Destroy;
begin
  FreeAndNil(FRequire);
  FreeAndNil(FEnsure);
  inherited;
end;

procedure TNodeSequence.Eval(const AContext:TContext;var AResult:variant);

  procedure Check(ANode:TNodeBase;AName:ansistring);//raises exception

    procedure doit(n:TNodeBase); var b:Boolean;
    begin
      b:=false;//nohint
      try
        b:=n.eval(AContext);
      except
        ExecError(AName+' check failed: boolean expected in '+AContext.nsLocal.GetFullName);
      end;
      if not b then
        ExecError(AName+' check failed in '+AContext.nsLocal.GetFullName);
    end;

  var i:integer;
  begin
    if ANode is TNodeSequence then begin
      for i:=0 to ANode.SubNodeCount-1 do
        doit(ANode.SubNode(i));
    end else
      doit(ANode);
  end;

var i:integer;
begin
  if FRequire<>nil then
    Check(FRequire,'Requirement');

  for i:=0 to SubNodeCount-1 do begin
    SubNode(i).Eval(AContext,AResult);

    if not AContext.ExecMask then break;  //ExecMask handling
  end;

  if FEnsure<>nil then
    Check(FEnsure,'Ensurement');
end;

{ TNodeWith }

procedure TNodeWith.Eval(const AContext: TContext; var AResult: Variant);
var i:integer;pushed:integer;sn:TNodeBase;o:TObject;
begin
  pushed:=0;
  try
    with AContext do for i:=0 to SubNodeCount-2 do begin
      WithStack.Push(VarAsObjectOrInvoker(SubNode(i).Eval(AContext)));
      inc(pushed);
    end;

    sn:=SubNode(SubNodeCount-1);
    if sn<>nil then
      sn.Eval(AContext,AResult);

  finally
    with AContext do for i:=0 to pushed-1 do begin
      o:=WithStack.Pop;
      if(o<>nil)and(isUsing or (o is TVariantInvoker))then o.Free; //always free variantInvokers
    end;
  end;
end;

{ TNodeIf }

procedure TNodeIf.Eval(const AContext: TContext; var AResult: Variant);
var sn:TNodeBase;
begin
  if SubNode(0).Eval(AContext)then sn:=SubNode(1)
                              else sn:=SubNode(2);
  if sn<>nil then
    sn.Eval(AContext,AResult);
end;

{ TNodeIteration }

procedure TNodeIteration.HandleBreak(const AContext:TContext);
begin with AContext do begin
  if FBreakCnt<=0 then exit;
  if FBreakCnt=$7FFFFFFF{default break without parameter} then begin
    {if not FTightlyNested then} //original pascal not works like this, this FTightlyNested thing was a dead end
      FBreakCnt:=0;
  end else begin
    Dec(FBreakCnt);
  end;
end;end;

{ TNodeWhile }

procedure TNodeWhile.Eval(const AContext: TContext; var AResult: Variant);
var snCondition,snBlock:TNodeBase;

  function CheckCondition:boolean;    //nem lesz hatasa a postfix operationoknak, hogy olyan legyen itt a ++, mint a c-ben, de lehet, hogy faszsag...
  begin
    with AContext do try
      BlockPostfixAssignments:=true;
      result:=snCondition.Eval(AContext);
    finally
      BlockPostfixAssignments:=false;
    end;
  end;

var PostfixFrom:integer;
begin
  snCondition:=SubNode(0);
  PostfixFrom:=AContext.PendingPostfixOperations.FCount;

  if CheckCondition then begin
    snBlock:=SubNode(1);
    repeat
      if snBlock<>nil then
        snBlock.Eval(AContext,AResult);
      AContext.FinalizePostfixOperations(PostfixFrom);

      AContext.FContinueing:=false;
      if not AContext.ExecMask then break;  //ExecMask handling

    until not CheckCondition;
  end else begin //unless
    if AContext.ExecMask then if SubNode(2)<>nil then
      SubNode(2).Eval(AContext,AResult);
  end;

  HandleBreak(AContext);
end;

{ TNodeRepeat }

procedure TNodeRepeat.Eval(const AContext: TContext; var AResult: Variant);
var vBool:Variant;
    o1,o2:TNodeBase;
begin
  o1:=SubNode(0);
  o2:=SubNode(1);
  repeat
    if o1<>nil then o1.Eval(AContext,AResult);

    AContext.FContinueing:=false;
    if not AContext.ExecMask then break;  //ExecMask handling

    o2.Eval(AContext,vBool)
  until vBool;

  HandleBreak(AContext);
end;

{ TNodeRaise }

procedure TNodeRaise.Eval(const AContext: TContext; var AResult: Variant);
begin
  raise VarAsObject(FOp1.Eval(AContext),Exception);
end;

{ TNodeFor }

function TNodeFor.Clone:TNodeBase;
begin
  Result:=Inherited;
  TNodeFor(Result).FForType:=FForType;
  TNodeFor(Result).FDescending:=FDescending;
end;

procedure TNodeFor.Eval(const AContext: TContext; var AResult: Variant);
var i,j:integer;
    nIndex,nStep,nBlock,nWhere:TNodeBase;
    dest,step,tmp:variant;
    pidx,pset:PVariant;
    worked:boolean;
    ft:TForType;
    s:ansistring;
    o:tobject;

    iStep,iDest:integer;piIdx:pinteger;
    i64Step,i64Dest:int64;pi64Idx:pint64;

  function Iterate:boolean;//pidx^ must be set,  result:must stop the for
  var b:boolean;
  begin
    if nWhere=nil then b:=true
                  else b:=nWhere.Eval(AContext);  //complete boolean eval suxx, when using variants
    if b then begin
      if nBlock<>nil then
        nBlock.Eval(AContext,AResult);
      worked:=true;
    end;

    AContext.FContinueing:=false;
    result:=not AContext.ExecMask;  //ExecMask  Handling
  end;

  var isInt64:boolean;//reset to false
  function VarIsInt(const v:variant):boolean;
  begin with TVarData(v)do begin
    if VType in[varByte,varShortInt,varWord,varSmallint,varInteger]then exit(true);
    if VType in[varLongWord,varInt64]then begin isInt64:=true;exit(true)end;
    result:=false;
  end;end;

begin
  nIndex:=SubNode(0).SubNode(0);
  nStep:=SubNode(2);
  nWhere:=SubNode(3);
  nBlock:=SubNode(4);

  if FForType=ftIn then begin //for in
    pidx:=nIndex.RefPtr(AContext);//ref to index
    pset:=SubNode(0).SubNode(1).RefPtr(AContext,tmp);

    if VarIsObject(pset^) then begin
      o:=VarAsObject(pset^);
      if o=nil then
        ExecError('For-loop: Cannot enumerate NIL object');

      if o is TList then with TList(o)do begin
        if FDescending then for i:=Count-1 downto 0 do begin pidx^:=VObject(TObject(Items[i]));if Iterate then break;end
                       else for i:=0 to Count-1     do begin pidx^:=VObject(TObject(Items[i]));if Iterate then break;end
      end else if o is TComponent then with TComponent(o)do begin
        if FDescending then for i:=ComponentCount-1 downto 0 do begin pidx^:=VObject(Components[i]);if Iterate then break;end
                       else for i:=0 to ComponentCount-1     do begin pidx^:=VObject(Components[i]);if Iterate then break;end
      end else if o is TCollection then with TCollection(o)do begin
        if FDescending then for i:=Count-1 downto 0 do begin pidx^:=VObject(Items[i]);if Iterate then break;end
                       else for i:=0 to Count-1     do begin pidx^:=VObject(Items[i]);if Iterate then break;end
      end else if o is THetObjectList then with THetObjectList(o)do begin
        if FDescending then for i:=Count-1 downto 0 do begin pidx^:=VObject(ByIndex[i]);if Iterate then break;end
                       else for i:=0 to Count-1     do begin pidx^:=VObject(ByIndex[i]);if Iterate then break;end;
      end else
        ExecError('For-loop: Cannot enumerate '+toPas(o.ClassName)+' object');

    end else if VarIsStr(pset^)then begin
      s:=ansistring(pset^);
      for i:=1 to length(s)do begin
        pidx^:=s[i];//value
        if Iterate then break;
      end;
    end else if VarIsArray(pset^)then begin
      for i:=VarLow(pset^) to varHigh(pset^)do begin
        pidx^:=VReference(VarArrayAccess(pset^,i));//value
        if Iterate then break;
      end;
    end else if VarIsSet(pset^) then begin
      with VarAsSetArray(pset^)do for j:=0 to Elements.FCount-1 do with Elements.FItems[j]do begin
        if typ=stSingle then begin //single
          pidx^:=VReference(e1);
          if Iterate then break;
        end else if e1<=e2 then begin//range
          pidx^:=e1;

          isInt64:=false;
          if VarIsInt(e1)and VarIsInt(e2)then
            if isInt64 then begin//optimized int64
              pi64Idx:=@TVarData(pidx^).VInt64;i64Dest:=e2;
              while pi64idx^<=i64Dest do begin
                if Iterate then break;
                Inc(pi64idx^);
              end;
            end else begin//int32 optimization
              piIdx:=@TVarData(pidx^).VInteger;iDest:=e2;
              while piIdx^<=iDest do begin
                if Iterate then break;
                Inc(piIdx^);
              end;
            end
          else begin//other types, variants
            while pidx^<=e2 do begin
              if Iterate then break;
              VarInc(pidx^);
            end;
          end;
        end;
      end;
    end else
      ExecError('Fol-loop: Cannot enumerate type '+topas(VarTypeAsText(VarType(pset^))));

  end else begin //standard for
    pidx:=nIndex.RefPtr(AContext);//ref to index
    SubNode(0).SubNode(1).Eval(AContext,pIdx^);//idx:=source
    SubNode(1).Eval(AContext,Dest);//read dest

    worked:=false;
    if nStep=nil then begin //no step
      if FForType=ftTowards then begin
        if pidx^<=dest then begin ft:=ftTo;end
                       else begin ft:=ftDownTo;end;
      end else
        ft:=FForType;
      case ft of
        ftTo:step:=1;
        ftDownTo:step:=-1;
      end;
    end else begin//step
      nStep.Eval(AContext,step);
      if Step=0 then ExecError('Step cannot be 0 in for-loop');
      if Step>0 then ft:=ftTo
                else ft:=ftDownTo;
    end;

    isInt64:=false;
    if varIsInt(pidx^)and varIsInt(dest)and varIsInt(step)then begin//optimizations
      if isInt64 then begin
        pi64Idx:=@TVarData(pidx^).VInt64;i64Dest:=dest;i64Step:=step;
        case ft of  //int64 optimization
          ftTo:while pi64idx^<=i64dest do begin
            if Iterate then break;;
            pi64idx^:=pi64idx^+i64Step;
          end;
          ftDownTo:while pi64idx^>=i64dest do begin
            if Iterate then break;;
            pi64idx^:=pi64idx^+i64Step;
          end;
        end;
      end else begin  //int32 optimization
        piIdx:=@TVarData(pidx^).VInteger;iDest:=dest;iStep:=step;
        case ft of  //int32 optimization
          ftTo:while piidx^<=idest do begin
            if Iterate then break;;
            piidx^:=piidx^+iStep;
          end;
          ftDownTo:while piidx^>=idest do begin
            if Iterate then break;;
            piidx^:=piidx^+iStep;
          end;
        end;
      end;
    end else//other types ->variant
      case ft of
        ftTo:while pidx^<=dest do begin
          if Iterate then break;;
          pidx^:=pidx^+step; //C-s stilusuan, dest+step a vége
        end;
        ftDownTo:while pidx^>=dest do begin
          if Iterate then break;;
          pidx^:=pidx^+step;
        end;
      end;
  end;

  if AContext.ExecMask then if(not worked)and(SubNode(5)<>nil)then begin//unless
    SubNode(5).Eval(AContext,AResult);
  end;

  HandleBreak(AContext);
end;

{ TNodeCase }

procedure TNodeCase.Eval(const AContext: TContext; var AResult: Variant);
var val:Variant;
    i:integer;
    sc:TNodeSetConstruct;
    sn:TNodeBase;
begin
  SubNode(0).Eval(AContext,val);
  i:=1;while i<SubNodeCount-1 do begin
    sc:=TNodeSetConstruct(SubNode(i));
    if sc<>nil then begin
      if sc.EvalContains(val,AContext)then begin
        sn:=SubNode(i+1);
        if sn<>nil then
          sn.Eval(AContext,AResult);
        exit
      end;
    end else begin//else
      sn:=SubNode(i+1);
      if sn<>nil then
        sn.Eval(AContext,AResult);
    end;
    inc(i,2);
  end;
end;

// -----------------------------------------------------------------------------
// Inline Assembler support                                                   //
// -----------------------------------------------------------------------------

function TCompiler.CompileAsm:TNodeInlineAsm;

  procedure skipUntil(const StopChar:AnsiChar);
  begin
    repeat inc(ch) until(ch^=#0)or(ch^=StopChar);
    if ch<>#0 then inc(ch);
  end;

  procedure skipUntil2(const StopStr:AnsiString);
  begin
    repeat inc(ch) until(ch[0]=StopStr[1])and(ch[1]=StopStr[2])or(ch^=#0);
    if ch<>#0 then inc(ch);
    if ch<>#0 then inc(ch);
  end;

var bracketcnt:Integer;
    inComment:boolean;
    sb:IAnsiStringBuilder;
begin
  result:=TNodeInlineAsm.Create;
  sb:=AnsiStringBuilder(result.FCode);
  try
    case tk of
      tkAsm_IL :result.FMode:=asmIL;
      tkAsm_ISA:result.FMode:=asmISA;
    else CompileError('asm token expected (asm_il, asm_isa)');end;
    Parse;
    Expect(tkBracketOpen);
    //parse asm text
    bracketCnt:=1;inComment:=false;
    while true do case ch^ of  //keep ';' comments only
      '/':if ch[1]='/' then begin skipUntil(#10);sb.addStr(#13#10);end else
          if ch[1]='*' then skipUntil2('*/')else inc(ch);
      '(':if ch[1]='*' then skipUntil2('*)')
                       else begin
                         if not inComment then inc(bracketCnt);
                         sb.AddChar(ch^);inc(ch);
                       end;
      '{':skipUntil('}');
      ';':begin inComment:=true;sb.AddChar(ch^);inc(ch);end;
      #10:begin inComment:=false;sb.AddChar(ch^);inc(ch);end;
      ')':begin
            if not inComment then begin
              dec(bracketCnt);
              if bracketCnt=0 then begin
                inc(ch);break;
              end;
            end;
            sb.addChar(ch^);inc(ch);
          end;
      '!':if ch[1]='[' then begin //eval inserts
        sb.Finalize;
        AddIntArray(Result.FInsertPos,length(Result.FCode)+1);

        inc(ch,2);
        Parse;
        Result.AddSubNode(CompileExpression(true));
        Expect(tkSqrBracketClose);

      end else inc(ch);
      #0:CompileError('Unexpected eof');
      '\':begin inc(ch);sb.AddStr(#13#10);end;
    else
      sb.AddChar(ch^);
      inc(ch);
    end;
    sb.AddStr(#13#10);//biztos a biztos
    sb.Finalize;
    Parse;
  except
    sb:=nil;
    FreeAndNil(result);
  end;
end;

procedure TNodeInlineAsm.Eval(const AContext:TContext;var AResult:variant);
var res:ansistring;
    sb:IAnsiStringBuilder;
    i:integer;
begin
  if SubNodeCount=0 then
    AResult:=FCode
  else begin
    sb:=AnsiStringBuilder(res,true);
    for i:=0 to SubNodeCount-1 do begin
      if i=0 then sb.AddStr(copy(FCode,1,FInsertPos[i]-1))
             else sb.AddStr(copy(FCode,FInsertPos[i-1],FInsertPos[i]-FInsertPos[i-1]));
      sb.AddStr(ToStr(SubNode(i).Eval(AContext)));
    end;
    sb.AddStr(copy(FCode,FInsertPos[SubNodeCount-1]));
    sb.Finalize;
    AResult:=res;
  end;
end;

function _DefaultInline_Syntax(const AIdentifier:ansistring):TSyntaxKind;
begin
  result:=skWhitespace;
end;

initialization
  _Asm_il_syntax:=@_DefaultInline_Syntax;
  _Asm_isa_syntax:=@_DefaultInline_Syntax;

  rtticontext:=TRttiContext.Create;

  PrepareTokenSymbolTable;
  PrepareKeywordTable;

  PrepareTokenClassTable;
  nsObjectProperties:=TNameSpace.Create('ObjectProperties');
  nsVariantInvoker:=TNameSpace.Create('VariantInvoker');

finalization
  FreeAndNil(nsObjectProperties);
  FreeAndNil(nsVariantInvoker);

  FreeRegisteredNameSpaces;
  rtticontext.Free;
end.
