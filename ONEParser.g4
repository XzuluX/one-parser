parser grammar ONEParser;

options { tokenVocab=ONELexer; superClass = ONEParserBase; }

compilation_unit
  : NEWLINE? extern_alias_section? (extern_alias_directive NEWLINE)* using_section* (using_directive NEWLINE)* (attribute_list NEWLINE)* (member_declaration NEWLINE?)* EOF
  ;

extern_alias_section
  : EXTERN ALIAS indented_extern_alias_block
  ;

indented_extern_alias_block
  : ':' NEWLINE INDENT (identifier_token NEWLINE?)+ DEDENT
  ;

extern_alias_directive
  : EXTERN ALIAS identifier_token
  ;

using_section
  : GLOBAL? prefix=(USING | IMPORT) STATIC? indented_using_block
  ;

indented_using_block
  : ':' NEWLINE INDENT (name_element NEWLINE?)+ DEDENT
  ;

using_directive
  : (GLOBAL NEWLINE?)? prefix=(USING | IMPORT) (STATIC NEWLINE? | name_equals)? name
  ;

indented_using_directive
  : (GLOBAL NEWLINE?)? (STATIC NEWLINE? | name_equals)? name
  ;

name_equals
  : identifier_name '='
  ;

identifier_name
  : GLOBAL
  | identifier_token
  ;

name
  : identifier_name '::' simple_name #aliasQualifiedName
  | name '.' simple_name #qualifiedName
  | simple_name          #simpleName
  ;

cascade_name
  : name indented_cascade_name_block
  ;

indented_cascade_name_block
  : NEWLINE INDENT (cascade_name_element NEWLINE?)+ DEDENT
  ;

cascade_name_element
  : OP_RANGE name
  ;

name_element
  : indented_using_directive
  | cascade_name
  ;

simple_name
  : generic_name
  | identifier_name
  ;

generic_name
  : identifier_token type_argument_list
  ;

type_argument_list
  : '<' (type (',' type)*)? '>'
  ;

attribute_list
  : '[' attribute_target_specifier? attribute (',' attribute)* ']' NEWLINE?
  ;

attribute_target_specifier
  : syntax_token ':'
  ;

attribute
  : name attribute_argument_list?
  ;

attribute_argument_list
  : '(' (attribute_argument (',' attribute_argument)*)? ')'
  ;

attribute_argument
  : (name_equals? | name_colon?) expression
  ;

name_colon
  : identifier_name ':'
  ;

member_declaration
  : { this.IsGlobalStatement() }?
    global_statement
  | base_field_declaration
  | base_method_declaration
  | access_level_section
  | base_namespace_declaration
  | base_property_declaration
  | base_type_declaration
  | delegate_declaration
  //| enum_member_declaration
  //| incomplete_member
  ;

base_field_declaration
  : event_field_declaration
  | field_declaration
  | counter_declaration
  ;

event_field_declaration
  : attribute_list* (modifier NEWLINE?)* EVENT variable_declaration NEWLINE
  ;

modifier
  : ABSTRACT
  | ASYNC
  | CONST
  | EXTERN
  | FIXED
  | IN
  | INTERNAL
  | NEW
  | OVERRIDE
  | PARTIAL
  | PRIVATE
  | PROTECTED
  | PUBLIC
  | READONLY
  | REF
  | OUT
  | PARAMS
  | REQUIRED
  | SEALED
  | STATIC
  | THIS
  | UNSAFE
  | VIRTUAL
  | VOLATILE
  | ext=extended_modifier
  ;

extended_modifier
  : poI=PROTECTED OR INTERNAL  // protected internal
  | paI=PROTECTED AND INTERNAL // private protected
  ;

variable_declaration
  : variable_declarator (',' variable_declarator)* type equals_multiple_value_clause?
  ;

variable_declarator
  : identifier_token bracketed_argument_list?
  ;

bracketed_argument_list
  : '[' argument (',' argument)* ']'
  ;

argument
  : one_argument
  | nameCol=name_colon? refKind=(REF | OUT | IN)? exp=expression
  ;

one_argument
  : nameCol=name_colon? exp=expression refKind=(REF | OUT | IN)
  ;

equals_value_clause
  : '=' expression
  ;

equals_multiple_value_clause
  : '=' expression (',' expression)*
  ;

field_declaration
  : attribute_list* (modifier NEWLINE?)* variable_declaration NEWLINE
  ;

access_level_section
  : modifier+ indented_member_block
  ;

base_method_declaration
  : method_or_constructor_declaration
  | conversion_operator_declaration
  | destructor_declaration
  | operator_declaration
  ;

parameter_list
  : '(' (parameter (',' parameter)*)? ')'
  ;

parameter
  : one_parameter
  | attribute_list* modifier* identifier_token type? equals_value_clause?
  ;

one_parameter
  : attribute_list* identifier_token modifier+ type? equals_value_clause?
  ;

constructor_initializer
  : ':' kind=(BASE | THIS) arg=argument_list
  ;

argument_list
  : '(' (argument (',' argument)*)? ')'
  ;

block
  : attribute_list* '{' statement* '}'
  ;

statement_block
  : empty_block
  | ':' small_statements
  | attribute_list* ':' indented_statement_block
  ;

labeled_statement_block
  : empty_block
  | ':' small_statements
  | attribute_list* ':' unindented_statement_block
  ;

unindented_statement_block
  : NEWLINE (statement NEWLINE?)+
  ;

statement_block_without_colon
  : small_statements
  | attribute_list* indented_statement_block
  ;

small_statements
  : small_statement (';' small_statement)* NEWLINE?
  ;

small_statement
  : break_statement
  | continue_statement
  | throw_statement
  | on_trigger_statement
  | send_trigger_statement
  | small_expression_statement
  | goto_statement
  | return_statement
  ;

small_expression_statement
  : attribute_list* expression
  ;

indented_statement_block
  : NEWLINE INDENT (statement NEWLINE?)+ DEDENT
  ;

arrow_expression_clause
  : '=>' expression
  ;

conversion_operator_declaration
  : attribute_list* (modifier NEWLINE?)* keyWord=(IMPLICIT | EXPLICIT) NEWLINE? explicit_interface_specifier? OPERATOR CHECKED? type parameter_list (statement_block | arrow_expression_clause)
  ;

explicit_interface_specifier
  : name '.'
  ;

destructor_declaration
  : attribute_list* (modifier NEWLINE?)* '~' identifier_token parameter_list (statement_block | arrow_expression_clause)
  ;

method_or_constructor_declaration
  : attribute_list* (modifier NEWLINE?)* explicit_interface_specifier? identifier_token type_parameter_list? parameter_list type? type_parameter_constraint_clause* constructor_initializer? (statement_block | arrow_expression_clause)?
  ;

type_parameter_list
  : '<' type_parameter (',' type_parameter)* '>'
  ;

type_parameter
  : attribute_list* keyWord=(IN | OUT)? identifier_token
  ;

type_parameter_constraint_clause
  : WHERE identifier_name OP_DERIVATION type_parameter_constraint (',' type_parameter_constraint)*
  ;

type_parameter_constraint
  : class_or_struct_constraint
  | constructor_constraint
  | default_constraint
  | type_constraint
  ;

class_or_struct_constraint
  : classKind=CLASS '?'?
  | structKind=STRUCT '?'?
  ;

constructor_constraint
  : NEW '(' ')'
  ;

default_constraint
  : DEFAULT
  ;

type_constraint
  : type
  ;

operator_declaration
  : attribute_list* (modifier NEWLINE?)* explicit_interface_specifier? OPERATOR CHECKED?
    op=(PLUS | MINUS | BANG | TILDE | OP_INC | OP_DEC | STAR | DIV | PERCENT | OP_LEFT_SHIFT | OP_RIGHT_SHIFT
    /*| '>>>'*/ | BITWISE_OR | AMP | CARET | OP_EQ | OP_NE | LT | OP_LE | GT | OP_GE | FALSE | TRUE | IS)
    parameter_list type (statement_block | arrow_expression_clause)
  ;

base_namespace_declaration
  : file_scoped_namespace_declaration
  | indented_namespace_declaration
  ;

file_scoped_namespace_declaration
  : attribute_list* modifier* NAMESPACE name NEWLINE extern_alias_section? (extern_alias_directive NEWLINE)* using_section* (using_directive NEWLINE)* (member_declaration NEWLINE?)*
  ;

indented_namespace_declaration
  : attribute_list* modifier* NAMESPACE name indented_namespace_block
  ;

indented_namespace_block
  : ':' NEWLINE INDENT extern_alias_section? (extern_alias_directive NEWLINE)* using_section* (using_directive NEWLINE)* (member_declaration NEWLINE?)* DEDENT
  ;

base_property_declaration
  : event_declaration
  | indexer_declaration
  | property_declaration
  ;

event_declaration
  : attribute_list* modifier* EVENT type explicit_interface_specifier? identifier_token (accessor_list | ';')
  ;

accessor_list
  : '{' accessor_declaration* '}'
  ;

accessor_block
  : ':' accessors equals_value_clause?
  | indented_accessor_list
  ;

indented_accessor_list
  : ':' NEWLINE INDENT (accessor_declaration NEWLINE?)+ DEDENT
  ;

accessors
  : accessor_declaration (';' accessor_declaration)*
  ;

accessor_declaration
  : attribute_list* modifier* (kind=(GET | SET | INIT | ADD | REMOVE) | id=identifier_token) (statement_block | arrow_expression_clause)?
  ;

indexer_declaration
  : attribute_list* modifier* explicit_interface_specifier? THIS bracketed_parameter_list type (accessor_block | arrow_expression_clause)
  ;

bracketed_parameter_list
  : '[' parameter (',' parameter)* ']'
  ;

property_declaration
  : attribute_list* (modifier NEWLINE?)* explicit_interface_specifier? identifier_token type (accessor_block | (arrow_expression_clause | equals_value_clause))
  ;

interface_accessor
  : ':' modifier* accessor ( ';' modifier* accessor)?
  ;

accessor
  : GET | SET | INIT
  ;

base_type_declaration
  : enum_declaration
  | type_declaration
  ;

enum_declaration
  : attribute_list* modifier* ENUM identifier_token enum_base_list? enum_block
  ;

enum_block
  : ':' enum_members
  | indented_enum_declaration
  ;

indented_enum_declaration
  : ':' NEWLINE INDENT enum_members DEDENT
  ;

enum_members
  : enum_member_declaration (',' NEWLINE? enum_member_declaration)* ','? NEWLINE?
  ;

base_list
  : OP_DERIVATION base_type (',' base_type)*
  ;

enum_base_list
  : base_type (',' base_type)*
  ;

base_type
  : primary_constructor_base_type
  | simple_base_type
  ;

primary_constructor_base_type
  : type arg=argument_list
  ;

simple_base_type
  : type
  ;

enum_member_declaration
  : attribute_list* modifier* identifier_token equals_value_clause?
  ;

type_declaration
  : class_declaration
  | functionblock_declaration
  | interface_declaration
  | record_declaration
  | struct_declaration
  ;

class_declaration
  : attribute_list* (modifier NEWLINE?)* CLASS identifier_token type_parameter_list? parameter_list? base_list? type_parameter_constraint_clause* indented_member_block
  ;

interface_declaration
  : attribute_list* (modifier NEWLINE?)* INTERFACE identifier_token type_parameter_list? parameter_list? base_list? type_parameter_constraint_clause* indented_member_block
  ;

record_declaration
  : attribute_list* (modifier NEWLINE?)* syntax_token keyWord=(CLASS | STRUCT)? identifier_token type_parameter_list? parameter_list? base_list? type_parameter_constraint_clause* indented_member_block?
  ;

struct_declaration
  : attribute_list* (modifier NEWLINE?)* STRUCT identifier_token type_parameter_list? parameter_list? base_list? type_parameter_constraint_clause* indented_member_block
  ;

indented_member_block
  : ':' NEWLINE INDENT (member_declaration NEWLINE?)+ DEDENT
  | empty_block
  ;

empty_block
  : ':' SEMICOLON NEWLINE
  ;

// function block rules

functionblock_declaration
  : attribute_list* modifier* FUNCTIONBLOCK identifier_token type_parameter_list? base_list? type_parameter_constraint_clause* indented_functionblock_member_block?
  ;

indented_functionblock_member_block
  : ':' NEWLINE INDENT functionblock_properties? (functionblock_member_declaration NEWLINE?)+ DEDENT
  ;

functionblock_properties
  : functionblock_property (',' NEWLINE? functionblock_property)* ','? NEWLINE?
  ;

functionblock_member_declaration
  : indented_connector_block
  | member_declaration
  ;

functionblock_property
  : functionblock_general_property
  | functionblock_valid_runmodes
  | functionblock_default_runmode
  ;

functionblock_valid_runmodes
  : kind=VALIDRUNMODES '=' identifier_token ('+' identifier_token)*
  ;

functionblock_default_runmode
  : kind=DEFAULTRUNMODE '=' identifier_token
  ;

indented_connector_block
  : kind=(INPUT | OUTPUT | LOCALSETTING | GLOBALSETTING | PERSISTENT) ':' NEWLINE INDENT(connector_declaration NEWLINE?)+ DEDENT
  ;

connector_declaration
  : with_expression
  | identifier_token type connector_block?
  ;

connector_block
  : ':' connector_properties
  | indented_connector_property_block
  ;

connector_properties
  : connector_row_property (',' connector_row_property)*
  ;

connector_row_property
  : fbProp=functionblock_general_property
  | exp=expression
  ;

indented_connector_property_block
  : ':' NEWLINE INDENT functionblock_connector_properties DEDENT
  ;

functionblock_connector_properties
  : functionblock_general_property (',' NEWLINE functionblock_general_property)* ','? NEWLINE
  ;

functionblock_general_property
  : kind=identifier_token '=' exp=expression
  ;

// truthtable rules

truth_table_statement
  : TRUTHTABLE truthTableBlock=indented_truth_table_block?
  ;

indented_truth_table_block
  : COLON NEWLINE INDENT (truth_table_element NEWLINE?)+ DEDENT
  ;

truth_table_element
  : conditions
  | decisions
  | actions
  ;

conditions
  : CONDITION group=identifier_name? conditionBlock=indented_condition_block?
  ;

indented_condition_block
  : COLON NEWLINE INDENT (condition_element NEWLINE?)+ DEDENT
  ;

condition_element
  : with_expression
  | alias_expression
  | condition_row
  ;

condition_row
  : id=identifier_name COLON conditionTypes=condition_types? values=condition_values?
  ;

condition_values
  : COLON condition_value (',' condition_value)*
  ;

condition_value
  : cond=(IDENTIFIER | TRUE | FALSE | UNDERSCORE)
  ;

decisions
  : DECISION decisionBlock=indented_decision_block?
  ;

indented_decision_block
  : COLON NEWLINE INDENT (decision_element NEWLINE?)+ DEDENT
  ;

decision_element
  : id=identifier_name COLON action=action_values?
  ;

action_values
  : identifier_name (',' identifier_name)*
  ;

actions
  : ACTION indented_action_block
  ;

indented_action_block
  : COLON NEWLINE INDENT (action_element NEWLINE?)+ DEDENT
  ;

action_element
  : with_expression
  | alias_expression
  | action_method
  | action_expression_row
  ;

action_method
  : id=identifier_name statement_block
  ;

action_expression_row
  : id=identifier_name ':' expTypes=expression_row_types
  ;

expression_row_types
  : expression_row_type (COMMA expression_row_type)*
  ;

expression_row_type
  : discard=discard_pattern
  | exp=expression
  ;

// state machine rules

trigger_declaration
  : TRIGGER trigger_block
  ;

trigger_block
  : COLON trigger_members
  | indented_trigger_declaration
  ;

indented_trigger_declaration
  : COLON NEWLINE INDENT trigger_members DEDENT
  ;

trigger_members
  : trigger_member_declaration (',' NEWLINE? trigger_member_declaration)* ','? NEWLINE?
  ;

trigger_member_declaration
  : id=identifier_name
  ;

on_trigger_statement
  : ON id=identifier_name (op=OP_AND exp=expression)? statement_block
  ;

send_trigger_statement
  : SEND id=identifier_name TO to=identifier_name
  ;

statemachine_statement
  : STATEMACHINE id=identifier_name? stateMachineBlock=indented_statemachine_block?
  ;

indented_statemachine_block
  : COLON NEWLINE INDENT (statemachine_element NEWLINE?)+ DEDENT
  ;

statemachine_element
  : trigger_declaration
  | state_element
  | indented_finally_block
  ;

state
  : state_modifier* STATE id=identifier_name indented_state_block
  ;

indented_state_block
  : empty_block
  | COLON NEWLINE INDENT (state_element NEWLINE?)+ DEDENT
  ;

state_element
  : state_modifier_section
  | indented_init_block
  | indented_entry_block
  | indented_during_block
  | indented_exit_block
  | state
  ;

indented_init_block
  : INIT statement_block
  ;

indented_entry_block
  : ENTRY statement_block
  ;

indented_during_block
  : DURING statement_block
  ;

indented_exit_block
  : EXIT statement_block
  ;

indented_finally_block
  : FINALLY statement_block
  ;

state_modifier_section
  : state_modifier* indented_state_element_block
  ;

indented_state_element_block
  : COLON NEWLINE INDENT (state NEWLINE?)+ DEDENT
  ;

state_modifier
  : PARALLEL
  ;

// counter rules

counter_declaration
  : modifier* COUNTER id=identifier_name counter_block
  ;

counter_block
  : ':' counter_members
  | indented_counter_declaration
  ;

indented_counter_declaration
  : ':' NEWLINE INDENT counter_members DEDENT
  ;

counter_members
  : counter_member_declaration (',' NEWLINE? counter_member_declaration)* ','? NEWLINE?
  ;

counter_member_declaration
  : id=identifier_name ASSIGNMENT exp=expression
  ;

// with shortcut rule

with_shortcut_statement
  : WITH exp=expression ':' indented_statement_block
  ;

// alias shortcut rule

alias_shortcut_statement
  : alias_expression ':' indented_statement_block
  ;

// cascade notation

cascade_statement
  : exp=expression indented_cascade_block
  ;

indented_cascade_block
  : NEWLINE INDENT (cascade_element NEWLINE?)+ DEDENT
  ;

cascade_element
  : OP_RANGE exp=expression
  ;

delegate_declaration
  : attribute_list* modifier* DELEGATE identifier_token type_parameter_list? parameter_list type? type_parameter_constraint_clause*
  ;

global_statement
  : attribute_list* modifier* statement
  ;

incomplete_member
  : attribute_list* modifier* type
  ;

array_type
  : basic_type array_rank_specifier+
  ;

type
  : array_type                  #arrayTypeExpression
  | type post=(INTERR | STAR)   #nullableOrPointerTypeExpression
  | re=REF ro=READONLY? type    #refReadonlyExpression
  | basic_type                  #basicType
  ;

basic_type
  : name                        #nameExpression
  | predefined_identifiers      #predefinedIdentifiersExpression
  | function_pointer_type       #functionPointerTypeExpression
  | omitted_type_argument       #omittedTypeArgumentExpression
  | predefined_type             #predefinedTypeExpression
  | extended_type               #extendedTypeExpression
  | tuple_type                  #tupleTypeExpression
  ;

array_rank_specifier
  : standard_rank
  | multi_dim_rank
  ;

standard_rank
  : '[' (expression (',' expression)*)? ']'
  ;

multi_dim_rank
  : '[' COMMA+ ']'
  ;

function_pointer_type
  : DELEGATE '*' function_pointer_calling_convention? function_pointer_parameter_list
  ;

function_pointer_calling_convention
  : MANAGED function_pointer_unmanaged_calling_convention_list?
  | UNMANAGED function_pointer_unmanaged_calling_convention_list?
  ;

function_pointer_unmanaged_calling_convention_list
  : '[' function_pointer_unmanaged_calling_convention (',' function_pointer_unmanaged_calling_convention)* ']'
  ;

function_pointer_unmanaged_calling_convention
  : identifier_token
  ;

function_pointer_parameter_list
  : '<' function_pointer_parameter (',' function_pointer_parameter)* '>'
  ;

function_pointer_parameter
  : attribute_list* modifier* type
  ;

nullable_type
  : type '?'
  ;

omitted_type_argument
  : EPSILON
  ;

pointer_type
  : type '*'
  ;

predefined_type
  : BOOL
  | BYTE
  | CHAR
  | DECIMAL
  | DOUBLE
  | FLOAT
  | INT
  | LONG
  | OBJECT
  | SBYTE
  | SHORT
  | STRING
  | UINT
  | ULONG
  | USHORT
  | VOID
  ;

extended_type
  : INT8
  | IN8
  | UINT8
  | UI8
  | INT16
  | IN16
  | UINT16
  | UI16
  | INT32
  | IN32
  | UINT32
  | UI32
  | INT64
  | IN64
  | UINT64
  | UI64
  | FLOAT32
  | FL32
  | FLOAT64
  | FL64
  | DZ128
  | CR16
  | CR8
  | STRX
  ;

ref_type
  : REF READONLY? type
  ;

tuple_type
  : '(' tuple_element (',' tuple_element)+ ')'
  ;

tuple_element
  : identifier_token? type
  ;

basic_statement
  : break_statement
  | checked_statement
  | common_for_each_statement
  | continue_statement
  | yield_statement
  | do_statement
  | empty_statement
  | throw_statement
  | using_statement
  | on_trigger_statement
  | send_trigger_statement
  | alias_shortcut_statement
  | { this.IsDeclaration() }?
    local_declaration_statement
  | local_function_statement
  | cascade_statement
  | expression_statement
  | for_statement
  | if_statement
  | goto_statement
  | labeled_statement
  | lock_statement
  | return_statement
  | one_switch_statement
  | try_statement
  | unsafe_statement
  | fixed_statement
  | while_statement
  | with_shortcut_statement
  | truth_table_statement
  | statemachine_statement
  | const_statement_section
  ;

const_statement_section
  : CONST indented_const_variable_block
  ;

indented_const_variable_block
  : ':' NEWLINE INDENT (variable_declaration NEWLINE?)+ DEDENT
  ;

statement
  : basic_statement
  ;

break_statement
  : attribute_list* BREAK
  ;

checked_statement
  : attribute_list* kind=(CHECKED | UNCHECKED) statementBlock=statement_block
  ;

common_for_each_statement
  : for_each_statement
  | for_each_variable_statement
  ;

for_each_statement
  : attribute_list* aw=AWAIT? FOREACH identifier_token type IN exp=expression? statementBlock=statement_block?
  ;

for_each_variable_statement
  : attribute_list* aw=AWAIT? FOREACH var=expression IN exp=expression statementBlock=statement_block?
  ;

continue_statement
  : attribute_list* CONTINUE
  ;

do_statement
  : attribute_list* DO statementBlock=statement_block? whileKeyword=WHILE? cond=expression?
  ;

empty_statement
  : attribute_list* ';'
  ;

expression_statement
  : attribute_list* expression (NEWLINE | ';')
  ;

fixed_statement
  : attribute_list* FIXED variable_declaration statementBlock=statement_block
  ;

for_statement
  : for_statement_basic
  ;

for_statement_basic
  : attribute_list* FOR (varDecl=variable_declaration? | init=expressions?) (forColon=for_colon_extension | forTo=for_to_extension | forWhile=for_while_extension)?
  ;

for_colon_extension
  : ';' cond=expression? secondColon=';'? inc=expressions? statementBlock=statement_block?
  ;

for_to_extension
  : TO toExpression=expression? forStep=for_step? statementBlock=statement_block?
  ;

for_while_extension
  : WHILE cond=expression? forStep=for_step? statementBlock=statement_block?
  ;

for_step
  : STEP exp=expressions
  ;

expressions
  : expression (COMMA expression)*
  ;

goto_statement
  : attribute_list* GOTO keyWord=(CASE | DEFAULT | ELSE)? exp=expression?
  ;

if_statement
  : attribute_list* IF cond=expression? statementBlock=statement_block? elseClause=else_clause?
  ;

else_clause
  : ELSE (ifStatement=if_statement | statementBlock=statement_block?)
  ;

labeled_statement
  : attribute_list* identifier_token statementBlock=labeled_statement_block
  ;

local_declaration_statement
  : attribute_list* aw=AWAIT? us=USING? modifier* variable_declaration (NEWLINE | ';')?
  ;

local_function_statement
  : attribute_list* modifier* identifier_token type_parameter_list? parameter_list type? type_parameter_constraint_clause* (statement_block | (arrow_expression_clause))
  ;

lock_statement
  : attribute_list* LOCK exp=expression statementBlock=statement_block
  ;

return_statement
  : attribute_list* RETURN exp=expression?
  ;

switch_statement
  : attribute_list* SWITCH exp=expression ':' NEWLINE INDENT (switch_section NEWLINE?)+ DEDENT
  ;

switch_section
  : switch_label+ statementBlock=statement_block_without_colon+
  ;

switch_label
  : case_pattern_switch_label
  | case_switch_label
  | default_switch_label
  ;

case_pattern_switch_label
  : CASE pattern whenClause=when_clause? ':' NEWLINE?
  ;

one_switch_statement
  : attribute_list* SWITCH switchArgument=one_switch_argument? switchSections=switch_sections?
  ;

switch_sections
  : ':' NEWLINE INDENT (one_switch_section NEWLINE?)+ DEDENT
  ;

one_switch_section
  : with_expression
  | alias_expression
  | one_case_section
  ;

one_case_section
  : one_switch_label+ ':' element=one_case_section_element
  ;

one_switch_label
  : { this.IsCaseTypeLabel() }? one_case_switch_label
  | one_case_pattern_switch_label
  | one_default_switch_label
  ;

one_case_switch_label
  : CASE conditionTypes=condition_types NEWLINE?
  ;

one_case_pattern_switch_label
  : CASE pattern whenClause=when_clause? NEWLINE?
  ;

one_default_switch_label
  : DEFAULT
  | ELSE
  ;

one_case_section_element
  : expTypes=expression_row_types
  | statementBlock=statement_block_without_colon?
  ;

with_expression
  : WITH left=left_with_expressions? (':' right=right_with_expressions)?
  ;

left_with_expressions
  : left_with_expression (COMMA left_with_expression)*
  ;

right_with_expressions
  : right_with_expression (COMMA right_with_expression)*
  ;

left_with_expression
  : op=(LT | OP_LE | GT | OP_GE | OP_EQ | OP_NE)? exp=expression
  ;

right_with_expression
  : exp=expression op=assignment_operators?
  | basicStatement=basic_statement
  ;

alias_expression
  : ALIAS alias_assignment (COMMA alias_assignment)*
  ;

alias_assignment
  : id=alias_identifier ASSIGNMENT exp=expression
  ;

alias_identifier
  : IDENTIFIER
  ;

pattern
  : left=pattern op=(OR | AND) right=pattern #binaryPattern
  | range                 #rangePatternExtension
  | discard_pattern       #discardPattern
  | var_pattern           #varPattern
  | declaration_pattern   #declarationPattern
  | recursive_pattern     #recursivePattern
  | list_pattern          #listPattern
  | slice_pattern         #slicePattern
  | constant_pattern      #constantPattern
  | parenthesized_pattern #parenthesizedPattern
  | relational_pattern    #relationalPattern
  | type_pattern          #typePattern
  | unary_pattern         #unaryPattern
  ;

constant_pattern
  : expression
  ;

declaration_pattern
  : variable_designation type
  ;

variable_designation
  : discard_designation
  | parenthesized_variable_designation
  | single_variable_designation
  ;

discard_designation
  : UNDERSCORE
  ;

parenthesized_variable_designation
  : '(' (variable_designation (',' variable_designation)*)? ')'
  ;

single_variable_designation
  : identifier_token
  ;

discard_pattern
  : UNDERSCORE
  ;

list_pattern
  : '[' (pattern (',' pattern)* ','?)? ']' variable_designation?
  ;

parenthesized_pattern
  : '(' pattern ')'
  ;

recursive_pattern
  : recursive_positional_pattern
  | recursive_property_pattern
  ;

recursive_positional_pattern
  : variable_designation? positional_pattern_clause type?
  ;

recursive_property_pattern
  : variable_designation? property_pattern_clause type?
  ;

positional_pattern_clause
  : '(' (subpattern (',' subpattern)*)? ')'
  ;

subpattern
  : base_expression_colon? pattern
  ;

base_expression_colon
  : name_colon
  | expression_colon
  ;

expression_colon
  : exp=expression ':'
  ;

property_pattern_clause
  : '{' (subpattern (',' subpattern)* ','?)? '}'
  ;

relational_pattern
  : op=(OP_NE | LT | OP_LE | OP_EQ | GT | OP_GE) exp=const_expression     #relationalPatternRule
  | left=relational_pattern op=(OP_OR | OP_AND) right=relational_pattern  #relationalBinaryPattern
  ;

const_expression
  : member_binding_expression #contMemberBindingExpression
  | op=(BANG | AMP | STAR | PLUS | OP_INC | MINUS | OP_DEC | CARET | TILDE) exp=const_expression  #constPrefixUnaryExpression
  | left=const_expression op=(STAR | DIV | INT_DIV | PERCENT) right=const_expression              #constMultiplicativeExpression
  | left=const_expression op=(PLUS | MINUS) right=const_expression                                #constAdditiveExpression
  | left=const_expression op=(OP_LEFT_SHIFT | OP_RIGHT_SHIFT /*| '>>>'*/) right=const_expression  #constShiftExpression
  | '(' type ')' exp=const_expression   #constCastExpression
  | literal_expression                  #constLiteralExpression
  | basic_type                          #constTypeExpression
  ;

slice_pattern
  : '..' pattern?
  ;

type_pattern
  : type
  ;

unary_pattern
  : NOT pattern
  ;

var_pattern
  : variable_designation VAR
  ;

when_clause
  : WHEN exp=expression
  ;

case_switch_label
  : CASE exp=expression ':' NEWLINE?
  ;

default_switch_label
  : DEFAULT ':'
  ;

throw_statement
  : attribute_list* THROW exp=expression?
  ;

try_statement
  : attribute_list* TRY statementBlock=statement_block catch_clause* finallyClause=finally_clause?
  ;

catch_clause
  : CATCH declaration=catch_declaration? filter=catch_filter_clause? statementBlock=statement_block
  ;

catch_declaration
  : identifier_token? type
  ;

catch_filter_clause
  : WHEN exp=expression
  ;

finally_clause
  : FINALLY statementBlock=statement_block
  ;

unsafe_statement
  : attribute_list* UNSAFE statement_block
  ;

using_statement
  : attribute_list* aw=AWAIT? USING (varDecl=variable_declaration | exp=expression) statementBlock=statement_block
  ;

while_statement
  : attribute_list* WHILE cond=expression? statementBlock=statement_block?
  ;

yield_statement
  : attribute_list* YIELD kind=(RETURN | BREAK) exp=expression?
  ;

expression
  : anonymous_function_expression               #anonymousFunctionExpression
  | anonymous_object_creation_expression        #anonymousObjectCreationExpression
  | array_creation_expression                   #arrayCreationExpression
  | base_object_creation_expression             #baseObjectCreationExpression
  | { this.IsCollectionExpression() }?
    collection_expression                       #collectionExpression
  | exp=expression arg=bracketed_argument_list  #elementAccessExpression
  | exp=expression op=('.' | '->') simple_name  #memberAccessExpression
  | exp=expression arg=argument_list            #invocationExpression
  | member_binding_expression                   #memberBindingExpression
  | { this.IsElementAccessOrBinding() }?
    element_access_or_binding                   #elementAccessOrBindingExpression
  | exp=expression '?' notNull=expression       #conditionalAccessExpression
  | exp=expression op=(OP_INC | OP_DEC | BANG)  #postfixUnaryExpression
  | op=(BANG | AMP | STAR | PLUS | OP_INC | MINUS | OP_DEC | CARET | TILDE) exp=expression  #prefixUnaryExpression
  | exp=expression SWITCH expBlock=indented_switch_expression_block?                  #switchExpression
  | SWITCH arg=one_switch_argument? oneExpBlock=indented_one_switch_expression_block? #oneSwitchExpression
  | exp=expression WITH init=initializer_expression                              #withExpression
  | left=expression op=OP_MULT_POW right=expression                              #multiplicativePowerExpression
  | left=expression op=(STAR | DIV | INT_DIV | PERCENT) right=expression         #multiplicativeExpression
  | left=expression op=(PLUS | MINUS) right=expression                           #additiveExpression
  | left=expression op=(OP_LEFT_SHIFT | OP_RIGHT_SHIFT /*| '>>>'*/) right=expression #shiftExpression
  | left=expression op=(LT | OP_LE | GT | OP_GE) right=expression                #relationalExpression
  | left=expression IS right=expression                                          #isTypeTestingOrIsPatternExpression
  | left=expression IS pat=pattern                                               #isPatternExpression
  | left=expression AS right=expression                                          #asTypeTestingExpression
  | left=expression IN right=range                                               #inRangeExpression
  | left=expression op=(OP_EQ | OP_NE) right=expression                          #equalityExpression
  | left=expression op=AMP right=expression                                      #booleanLogicalAndExpression
  | left=expression op=CARET right=expression                                    #booleanLogicalXorExpression
  | left=expression op=BITWISE_OR right=expression                               #booleanLogicalOrExpression
  | left=expression op=OP_AND right=expression                                   #conditionalAndExpression
  | left=expression op=OP_OR right=expression                                    #conditionalOrExpression
  | left=expression OP_COALESCING right=expression                               #nullCoalescingOperatorExpression
  | '(' type ')' exp=expression               #castExpression
  | CHECKED '(' exp=expression ')'            #checkedExpression
  | UNCHECKED '(' exp=expression ')'          #uncheckedExpression
  | AWAIT exp=expression                      #awaitExpression
  | cond=expression '?' trueExp=expression ':' falseExp=expression #conditionalExpression
  | from=from_clause query=query_body         #queryExpression
  | declaration_expression                    #declarationExpression
  | default_expression                        #defaultExpression
  | implicit_array_creation_expression        #implicityArrayCreationExpression
  | implicit_stack_alloc_array_creation_expression  #implicitStackAllocArrayCreationExpression
  | initializer_expression                    #initializerExpression
  | instance_expression                       #instanceExpression
  | interpolated_string_expression            #interpolatedStringExpression
  | literal_expression                        #literalExpression
  | MAKEREF '(' exp=expression ')'            #makerefExpression
  | left=expression op=assignment_operators right=expression #assignmentExpression
  | omitted_array_size_expression             #omittedArraySizeExpression
  | '(' exp=expression ')'                    #parenthesizedExpression
  | left=expression OP_RANGE right=expression? #rightEmptyOrFullRangeExpression
  | OP_RANGE right=expression?                #leftOrTotalEmptyRangeExpression
  | REF exp=expression                        #refExpression
  | REFTYPE '(' exp=expression ')'            #reftypeExpression
  | REFVALUE '(' exp=expression ',' type ')'  #refvalueExpression
  | size_of_expression                        #sizeofExpression
  | stack_alloc_array_creation_expression     #stackallocArrayCreationExpression
  | THROW exp=expression                      #throwExpression
  | tuple_expression                          #tupleExpression
  | basic_type                                #typeExpression
  | type_of_expression                        #typeofExpression
  // pattern to expression mapping
  | declaration_pattern                       #declarationPatternExpression
  | list_pattern                              #listPatternExpression
  ;

assignment_operators
  : ASSIGNMENT
  | OP_ADD_ASSIGNMENT
  | OP_SUB_ASSIGNMENT
  | OP_MULT_ASSIGNMENT
  | OP_DIV_ASSIGNMENT
  | OP_INT_DIV_ASSIGNMENT
  | OP_MULT_POW_ASSIGNMENT
  | OP_MOD_ASSIGNMENT
  | OP_AND_ASSIGNMENT
  | OP_XOR_ASSIGNMENT
  | OP_OR_ASSIGNMENT
  | OP_LEFT_SHIFT_ASSIGNMENT
  | OP_RIGHT_SHIFT_ASSIGNMENT
  //| '>>>='
  | OP_COALESCING_ASSIGNMENT
  ;

anonymous_function_expression
  : anonymous_method_expression
  | lambda_expression
  ;

anonymous_method_expression
  : modifier* DELEGATE parameter_list? statement_block //expression?
  ;

lambda_expression
  : parenthesized_lambda_expression
  | simple_lambda_expression
  ;

parenthesized_lambda_expression
  : attribute_list* modifier* type? parameter_list '=>' (lambda_statement_block | expression)
  ;

lambda_statement_block
  : attribute_list* ':' indented_statement_block
  ;

simple_lambda_expression
  : attribute_list* modifier* parameter '=>' (lambda_statement_block | expression)
  ;

anonymous_object_creation_expression
  : NEW '{' (anonymous_object_member_declarator (',' anonymous_object_member_declarator)* ','?)? '}'
  ;

anonymous_object_member_declarator
  : name_equals? expression
  ;

array_creation_expression
  : NEW array_type initializer_expression?
  ;

initializer_expression
  : '{' (expression (',' expression)* ','?)? '}'
  ;

base_object_creation_expression
  : implicit_object_creation_expression
  | object_creation_expression
  ;

implicit_object_creation_expression
  : NEW argument_list initializer_expression?
  ;

object_creation_expression
  : NEW type argument_list? initializer_expression?
  ;

cast_expression
  : '(' type ')' expression
  ;

checked_expression
  : CHECKED '(' expression ')'
  | UNCHECKED '(' expression ')'
  ;

collection_expression
  : '[' (collection_element (',' collection_element)* ','?)? ']'
  ;

collection_element
  : spread_element
  | expression_element
  ;

expression_element
  : expression
  ;

spread_element
  : '..' expression
  ;

conditional_access_expression
  : expression '?' expression
  ;

conditional_expression
  : expression '?' expression ':' expression
  ;

declaration_expression
  : one_declaration_expression
  | { this.IsDeclarationExpression() }? variable_designation type
  ;

one_declaration_expression
  : { this.IsDeclarationExpression() }? variable_designation refKind=OUT type
  ;

default_expression
  : DEFAULT '(' type ')'
  ;

element_access_expression
  : expression bracketed_argument_list
  ;

element_access_or_binding
  : { this.IsImplicitElementAccess() }? implicit_element_access
  | element_binding_expression
  ;

element_binding_expression
  : bracketed_argument_list
  ;

implicit_array_creation_expression
  : NEW '[' COMMA* ']' init=initializer_expression
  ;

implicit_element_access
  : bracketed_argument_list
  ;

implicit_stack_alloc_array_creation_expression
  : STACKALLOC '[' ']' init=initializer_expression
  ;

instance_expression
  : base_expression
  | this_expression
  ;

base_expression
  : BASE
  ;

this_expression
  : THIS
  ;

raw_string_literal
  : RAW_STRING_LITERAL_START raw_string_content* RAW_STRING_LITERAL_END
  ;

raw_string_content
  : RAW_STRING_LITERAL_INSIDE
  | RAW_STRING_CONTENT
  ;

interpolated_string_expression
  : interpolated_regular_string
  | interpolated_verbatim_string
  | interpolated_implicit_regular_string
  | interpolated_raw_string
  ;

// interpolated regular string

interpolated_regular_string
  : INTERPOLATED_REGULAR_STRING_START interpolated_regular_string_content* DOUBLE_QUOTE_INSIDE
  ;

interpolated_regular_string_content
  : interpolated_regular_string_text
  | interpolation
  ;

interpolated_regular_string_text
  : interpolated_regular_string_text_token
  ;

interpolated_regular_string_text_token
  : DOUBLE_CURLY_INSIDE
  | REGULAR_CHAR_INSIDE
  | REGULAR_STRING_INSIDE
  ;

// interpolated verbatim string

interpolated_verbatim_string
  : INTERPOLATED_VERBATIM_STRING_START interpolated_verbatim_string_content* DOUBLE_QUOTE_INSIDE
  ;

interpolated_verbatim_string_content
  : interpolated_verbatim_string_text
  | interpolation
  ;

interpolated_verbatim_string_text
  : interpolated_verbatim_string_text_token
  ;

interpolated_verbatim_string_text_token
  : DOUBLE_CURLY_INSIDE
  | VERBATIM_DOUBLE_QUOTE_INSIDE
  | VERBATIM_INSIDE_STRING
  ;

// interpolated implicit string

interpolated_implicit_regular_string
  : INTERPOLATED_IMPLICIT_REGULAR_STRING_START interpolated_implicit_regular_string_content* IMPLICIT_SINGLE_QUOTE_INSIDE
  ;

interpolated_implicit_regular_string_content
  : interpolated_implicit_regular_string_text
  | interpolation
  ;

interpolated_implicit_regular_string_text
  : interpolated_implicit_regular_string_text_token
  ;

interpolated_implicit_regular_string_text_token
  : IMPLICIT_DOUBLE_CURLY_INSIDE
  | IMPLICIT_REGULAR_CHAR_INSIDE
  | IMPLICIT_DOUBLE_QUOTE_INSIDE
  | IMPLICIT_REGULAR_STRING_INSIDE
  ;

// interpolated raw string

interpolated_raw_string
  : startToken=INTERPOLATED_RAW_STRING_LITERAL_START interpolated_raw_string_content* endToken=RAW_INTERPOL_STRING_LITERAL_END
  ;

interpolated_raw_string_content
  : interpolated_raw_string_text
  | interpolation
  ;

  interpolated_raw_string_text
  : interpolated_raw_string_text_token
  ;

interpolated_raw_string_text_token
  : RAW_INTERPOL_STRING_LITERAL_INSIDE
  | RAW_INTERPOL_OPEN_BRACE_INSIDE
  | RAW_INTERPOL_CLOSED_BRACE_INSIDE
  | RAW_INTERPOL_STRING_CONTENT
  ;

interpolation
  : exp=expression intAlCl=interpolation_alignment_clause? intForCl=interpolation_format_clause?
  ;

interpolation_alignment_clause
  : ',' exp=expression
  ;

interpolation_format_clause
  : COLON fs=FORMAT_STRING+
  ;

literal_expression
  : ARGLIST
  | DEFAULT
  | FALSE
  | NULL_
  | TRUE
  | character_literal_token
  | multi_line_raw_string_literal_token
  | numeric_literal_token
  | single_line_raw_string_literal_token
  | string_literal_token
  | utf_8_multi_line_raw_string_literal_token
  | utf_8_single_line_raw_string_literal_token
  | utf_8_string_literal_token
  ;

make_ref_expression
  : MAKEREF '(' expression ')'
  ;

member_access_expression
  : expression ('.' | '->') simple_name
  ;

member_binding_expression
  : '.' simple_name
  ;

omitted_array_size_expression
  : EPSILON
  ;

from_clause
  : FROM type? identifier_token IN exp=expression
  ;

query_body
  : query=query_clause+ select=select_or_group_clause cont=query_continuation?
  ;

query_clause
  : from_clause
  | join_clause
  | let_clause
  | order_by_clause
  | where_clause
  ;

join_clause
  : JOIN type? identifier_token IN inExp=expression ON left=expression EQUALS right=expression join_into_clause?
  ;

join_into_clause
  : INTO identifier_token
  ;

let_clause
  : LET identifier_token '=' exp=expression
  ;

order_by_clause
  : ORDERBY ordering (',' ordering)*
  ;

ordering
  : exp=expression kind=(ASCENDING | DESCENDING)?
  ;

where_clause
  : WHERE exp=expression
  ;

select_or_group_clause
  : group_clause
  | select_clause
  ;

group_clause
  : GROUP group=expression BY by=expression
  ;

select_clause
  : SELECT exp=expression
  ;

query_continuation
  : INTO identifier_token query_body
  ;

ref_expression
  : REF expression
  ;

ref_type_expression
  : REFTYPE '(' expression ')'
  ;

ref_value_expression
  : REFVALUE '(' expression ',' type ')'
  ;

size_of_expression
  : SIZEOF '(' type ')'
  ;

stack_alloc_array_creation_expression
  : STACKALLOC type init=initializer_expression?
  ;

indented_switch_expression_block
  : ':' NEWLINE INDENT (switch_expression_arm NEWLINE?)+ DEDENT
  ;

switch_expression_arm
  : pattern whenClause=when_clause? '=>' exp=expression ','?
  ;

one_switch_argument
  : exp=expression
  | argument (',' argument)+
  ;

indented_one_switch_expression_block
  : ':' NEWLINE INDENT (one_switch_expression_arm NEWLINE?)+ DEDENT
  ;

one_switch_expression_arm
  : with_expression
  | alias_expression
  | one_expression_case
  | one_expression_default
  ;

one_expression_case
  : CASE left=condition_types '=>' right=expression
  ;

condition_types
  : condition_type (COMMA condition_type)*
  ;

condition_type
  : expression
  | pattern
  ;

range
  : closed_or_one_sided_range
  | half_open_or_one_sided_range
  ;

closed_or_one_sided_range
  : left=expression? OP_CLOSED_RANGE right=expression?
  ;

half_open_or_one_sided_range
  : left=expression? OP_HALF_OPEN_RANGE right=expression
  ;

one_expression_default
  : ELSE '=>' right=expression
  ;

throw_expression
  : THROW expression
  ;

tuple_expression
  : '(' argument (',' argument)+ ')'
  ;

type_of_expression
  : TYPEOF '(' type ')'
  ;

xml_node
  : xml_c_data_section
  | xml_comment
  | xml_element
  | xml_empty_element
  | xml_processing_instruction
  | xml_text
  ;

xml_c_data_section
  : '<![CDATA[' xml_text_literal_token* ']]>'
  ;

xml_comment
  : '<!--' xml_text_literal_token* '-->'
  ;

xml_element
  : xml_element_start_tag xml_node+ xml_element_end_tag
  ;

xml_element_start_tag
  : '<' xml_name xml_attribute* '>'
  ;

xml_name
  : xml_prefix? identifier_token
  ;

xml_prefix
  : identifier_token ':'
  ;

xml_attribute
  : xml_cref_attribute
  | xml_name_attribute
  | xml_text_attribute
  ;

xml_cref_attribute
  : xml_name '=' ('\'' | '"') cref ('\'' | '"')
  ;

cref
  : member_cref
  | qualified_cref
  | type_cref
  ;

member_cref
  : conversion_operator_member_cref
  | indexer_member_cref
  | name_member_cref
  | operator_member_cref
  ;

conversion_operator_member_cref
  : EXPLICIT OPERATOR CHECKED? type cref_parameter_list?
  | IMPLICIT OPERATOR CHECKED? type cref_parameter_list?
  ;

cref_parameter_list
  : '(' (cref_parameter (',' cref_parameter)*)? ')'
  ;

cref_parameter
  : IN? READONLY? type
  | OUT? READONLY? type
  | REF? READONLY? type
  ;

indexer_member_cref
  : THIS cref_bracketed_parameter_list?
  ;

cref_bracketed_parameter_list
  : '[' cref_parameter (',' cref_parameter)* ']'
  ;

name_member_cref
  : type cref_parameter_list?
  ;

operator_member_cref
  : OPERATOR CHECKED? ('+' | '-' | '!' | '~' | '++' | '--' | '*' | '/' | '%' | '<<' | '>>' | '>>>' | '|' | '&' | '^' | '==' | '!=' | '<' | '<=' | '>' | '>=' | FALSE | TRUE) cref_parameter_list?
  ;

qualified_cref
  : type '.' member_cref
  ;

type_cref
  : type
  ;

xml_name_attribute
  : xml_name '=' ('\'' | '"') identifier_name ('\'' | '"')
  ;

xml_text_attribute
  : xml_name '=' ('\'' | '"') xml_text_literal_token* ('\'' | '"')
  ;

xml_element_end_tag
  : '</' xml_name '>'
  ;

xml_empty_element
  : '<' xml_name xml_attribute* '/>'
  ;

xml_processing_instruction
  : '<?' xml_name xml_text_literal_token* '?>'
  ;

xml_text
  : xml_text_literal_token+
  ;

structured_trivia
  : directive_trivia
  | documentation_comment_trivia
  | skipped_tokens_trivia
  ;

directive_trivia
  : bad_directive_trivia
  | branching_directive_trivia
  | define_directive_trivia
  | end_if_directive_trivia
  | end_region_directive_trivia
  | error_directive_trivia
  | line_or_span_directive_trivia
  | load_directive_trivia
  | nullable_directive_trivia
  | pragma_checksum_directive_trivia
  | pragma_warning_directive_trivia
  | reference_directive_trivia
  | region_directive_trivia
  | shebang_directive_trivia
  | undef_directive_trivia
  | warning_directive_trivia
  ;

bad_directive_trivia
  : '#' syntax_token
  ;

branching_directive_trivia
  : conditional_directive_trivia
  | else_directive_trivia
  ;

conditional_directive_trivia
  : elif_directive_trivia
  | if_directive_trivia
  ;

elif_directive_trivia
  : '#' ELIF expression
  ;

if_directive_trivia
  : '#' IF expression
  ;

else_directive_trivia
  : '#' ELSE
  ;

define_directive_trivia
  : '#' DEFINE identifier_token
  ;

end_if_directive_trivia
  : '#' ENDIF
  ;

end_region_directive_trivia
  : '#' ENDREGION
  ;

error_directive_trivia
  : '#' ERROR
  ;

line_or_span_directive_trivia
  : line_directive_trivia
  | line_span_directive_trivia
  ;

line_directive_trivia
  : '#' LINE (numeric_literal_token | DEFAULT | DIRECTIVE_HIDDEN) string_literal_token?
  ;

line_span_directive_trivia
  : '#' LINE line_directive_position '-' line_directive_position numeric_literal_token? string_literal_token
  ;

line_directive_position
  : '(' numeric_literal_token ',' numeric_literal_token ')'
  ;

load_directive_trivia
  : '#' LOAD string_literal_token
  ;

nullable_directive_trivia
  : '#' NULLABLE (ENABLE | DISABLE | RESTORE) (WARNINGS | ANNOTATIONS)?
  ;

pragma_checksum_directive_trivia
  : '#' PRAGMA CHECKSUM string_literal_token string_literal_token string_literal_token
  ;

pragma_warning_directive_trivia
  : '#' PRAGMA WARNING (DISABLE | RESTORE) (expression (',' expression)*)?
  ;

reference_directive_trivia
  : '#' 'r' string_literal_token
  ;

region_directive_trivia
  : '#' REGION
  ;

shebang_directive_trivia
  : '#' '!'
  ;

undef_directive_trivia
  : '#' UNDEF identifier_token
  ;

warning_directive_trivia
  : '#' WARNING
  ;

documentation_comment_trivia
  : xml_node+
  ;

skipped_tokens_trivia
  : syntax_token*
  ;

base_argument_list
  : argument_list
  | bracketed_argument_list
  ;

base_cref_parameter_list
  : cref_bracketed_parameter_list
  | cref_parameter_list
  ;

base_parameter_list
  : bracketed_parameter_list
  | parameter_list
  ;

base_parameter
  : function_pointer_parameter
  | parameter
  ;

character_literal_token
  : DUMMY
  ;

expression_or_pattern
  : expression
  | pattern
  ;

identifier_token
  : IDENTIFIER
  | UNDERSCORE
  ;

predefined_identifiers
  : id=(NAMEOF | VAR)
  ;

interpolated_multi_line_raw_string_start_token
  : DUMMY
  ;

interpolated_raw_string_end_token
  : DUMMY
  ;

interpolated_single_line_raw_string_start_token
  : DUMMY
  ;

interpolated_string_text_token
  : DUMMY
  ;

multi_line_raw_string_literal_token
  : DUMMY
  ;

numeric_literal_token
  : INTEGER_LITERAL
  | HEX_INTEGER_LITERAL
  | BIN_INTEGER_LITERAL
  | REAL_LITERAL
  ;

single_line_raw_string_literal_token
  : DUMMY
  ;

string_literal_token
  : REGULAR_STRING
  | CHARACTER_LITERAL
  | SHORT_STRING
  | VERBATIM_STRING
  | raw_string_literal
  ;

syntax_token
  : ASSEMBLY
  | MODULE
  | RECORD
  | PROPERTY
  | FIELD
  | PARAM
  | EVENT
  | METHOD
  | RETURN
  | TYPE
  ;

utf_8_multi_line_raw_string_literal_token
  : DUMMY
  ;

utf_8_single_line_raw_string_literal_token
  : DUMMY
  ;

utf_8_string_literal_token
  : DUMMY
  ;

xml_text_literal_token
  : DUMMY
  ;
