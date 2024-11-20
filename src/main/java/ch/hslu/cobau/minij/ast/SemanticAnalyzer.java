package ch.hslu.cobau.minij.ast;

import ch.hslu.cobau.minij.ast.constants.IntegerConstant;
import ch.hslu.cobau.minij.ast.constants.*;
import ch.hslu.cobau.minij.ast.entity.*;
import ch.hslu.cobau.minij.ast.expression.*;
import ch.hslu.cobau.minij.ast.statement.*;
import ch.hslu.cobau.minij.ast.type.*;

import java.util.*;

public class SemanticAnalyzer extends BaseAstVisitor {
    // Global symbol tables for functions, globals, and structs
    private final Map<String, Declaration> globalVariables = new HashMap<>();
    private final Map<String, Function> functions = new HashMap<>();
    private final Map<String, Struct> structs = new HashMap<>();

    // Stack to manage scopes
    private final Deque<Map<String, Declaration>> scopes = new ArrayDeque<>();

    // Current function being analyzed
    private Function currentFunction = null;

    // Map to store types of expressions
    private final Map<Expression, Type> expressionTypes = new HashMap<>();

    // List to collect semantic errors
    private final List<String> errors = new ArrayList<>();

    public boolean analyze(Unit unit) {
        // Start analysis by visiting the unit
        unit.accept(this);
        // Return true if no errors were found
        return errors.isEmpty();
    }

    private void semanticError(String message) {
        errors.add(message);
        System.err.println("Semantic Error: " + message);
    }

    // Method to access errors if needed
    public List<String> getErrors() {
        return errors;
    }

    // Helper methods for types
    private void setType(Expression expr, Type type) {
        expressionTypes.put(expr, type);
    }

    private Type getType(Expression expr) {
        Type type = expressionTypes.get(expr);
        // Return VoidType to prevent null pointers
        return Objects.requireNonNullElseGet(type, VoidType::new);
    }

    // Lookup variable in scopes
    private Declaration lookupVariable(String name) {
        // Iterate scopes from innermost to outermost
        Iterator<Map<String, Declaration>> it = scopes.descendingIterator();
        while (it.hasNext()) {
            Map<String, Declaration> scope = it.next();
            if (scope.containsKey(name)) {
                return scope.get(name);
            }
        }
        // Then check global variables
        return globalVariables.get(name);
    }

    // Check if expression is assignable
    private boolean isAssignable(Expression expr) {
        return expr instanceof VariableAccess || expr instanceof FieldAccess || expr instanceof ArrayAccess;
    }

    // Check if types are compatible
    private boolean typesAreCompatible(Type expected, Type actual) {
        if (expected instanceof VoidType || actual instanceof VoidType) {
            // If either type is VoidType, they are not compatible
            return false;
        }
        return expected.equals(actual);
    }

    // Visitor methods

    @Override
    public void visit(Unit unit) {
        // Process structs first
        for (Struct struct : unit.getStructs()) {
            struct.accept(this);
        }

        // Process global variable declarations directly
        for (Declaration global : unit.getGlobals()) {
            String name = global.getIdentifier();
            Type type = global.getType();

            if (globalVariables.containsKey(name)) {
                semanticError("Duplicate global variable declaration: " + name);
            } else if (!isValidType(type)) {
                semanticError("Global variable '" + name + "' has invalid or undefined type: " + type);
            } else {
                globalVariables.put(name, global);
            }
        }

        // Process functions
        for (Function function : unit.getFunctions()) {
            function.accept(this);
        }
    }

    @Override
    public void visit(Struct struct) {
        String name = struct.getIdentifier();
        if (structs.containsKey(name)) {
            semanticError("Duplicate struct declaration: " + name);
        } else {
            structs.put(name, struct);
            // Check for duplicate field names and invalid types
            Set<String> fieldNames = new HashSet<>();
            for (Declaration field : struct.getDeclarations()) {
                String fieldName = field.getIdentifier();
                Type fieldType = field.getType();
                if (!fieldNames.add(fieldName)) {
                    semanticError("Duplicate field name '" + fieldName + "' in struct '" + name + "'");
                } else if (!isValidType(fieldType)) {
                    semanticError("Struct field '" + fieldName + "' has invalid or undefined type: " + fieldType);
                }
                // No need to add to scope here
            }
        }
    }

    @Override
    public void visit(Function function) {
        String name = function.getIdentifier();
        if (functions.containsKey(name)) {
            semanticError("Duplicate function declaration: " + name);
            return;
        }

        if (name.equals("main")) {
            // Check main function signature
            if (!function.getFormalParameters().isEmpty()) {
                semanticError("Main function must not have parameters");
            }
            if (!(function.getReturnType() instanceof IntegerType)) {
                semanticError("Main function must return integer");
            }
        }

        functions.put(name, function);

        // Start a new scope for the function
        Map<String, Declaration> functionScope = new HashMap<>();
        scopes.push(functionScope);
        currentFunction = function;

        // Add formal parameters to the scope
        Set<String> parameterNames = new HashSet<>();
        for (Declaration param : function.getFormalParameters()) {
            String paramName = param.getIdentifier();
            Type paramType = param.getType();
            if (!parameterNames.add(paramName)) {
                semanticError("Duplicate parameter name '" + paramName + "' in function '" + name + "'");
            } else if (paramType instanceof VoidType) {
                semanticError("Function parameter '" + paramName + "' cannot be of type void");
            } else {
                functionScope.put(paramName, param);
            }
        }

        // Visit the function body (statements)
        for (Statement stmt : function.getStatements()) {
            stmt.accept(this);
        }

        // Clean up
        scopes.pop();
        currentFunction = null;
    }

    @Override
    public void visit(DeclarationStatement declarationStmt) {
        Declaration declaration = declarationStmt.getDeclaration();
        String name = declaration.getIdentifier();
        Type type = declaration.getType();

        Map<String, Declaration> currentScope = scopes.peek();
        if (currentScope.containsKey(name)) {
            semanticError("Duplicate local variable declaration: " + name);
        } else if (!isValidType(type)) {
            semanticError("Local variable '" + name + "' has invalid or undefined type: " + type);
        } else {
            currentScope.put(name, declaration);
        }
    }

    @Override
    public void visit(AssignmentStatement assignment) {
        // Visit left and right expressions
        assignment.getLeft().accept(this);
        assignment.getRight().accept(this);

        // Get types
        Type leftType = getType(assignment.getLeft());
        Type rightType = getType(assignment.getRight());

        // Check if left is assignable
        if (!isAssignable(assignment.getLeft())) {
            semanticError("Left-hand side of assignment must be a variable, field access, or array access");
            return;
        }

        // Check types
        if (!typesAreCompatible(leftType, rightType)) {
            semanticError("Type mismatch in assignment: cannot assign " + rightType + " to " + leftType);
        }
    }

    @Override
    public void visit(VariableAccess varAccess) {
        String name = varAccess.getIdentifier();
        Declaration declaration = lookupVariable(name);
        if (declaration == null) {
            semanticError("Undefined variable: " + name);
            setType(varAccess, new VoidType()); // Set to void to prevent cascading errors
        } else {
            setType(varAccess, declaration.getType());
        }
    }

    @Override
    public void visit(IntegerConstant intConst) {
        setType(intConst, new IntegerType());
    }

    @Override
    public void visit(StringConstant strConst) {
        setType(strConst, new StringType());
    }

    @Override
    public void visit(TrueConstant trueConst) {
        setType(trueConst, new BooleanType());
    }

    @Override
    public void visit(FalseConstant falseConst) {
        setType(falseConst, new BooleanType());
    }

    @Override
    public void visit(CallExpression callExpr) {
        String functionName = callExpr.getIdentifier();

        // Look up the function
        Function function = functions.get(functionName);
        if (function == null) {
            // Check if it's a built-in function
            function = getBuiltInFunction(functionName);
            if (function == null) {
                semanticError("Undefined function: " + functionName);
                setType(callExpr, new VoidType());
                return;
            }
        }

        // Visit all arguments
        for (Expression arg : callExpr.getParameters()) {
            arg.accept(this);
        }

        // Check parameter count
        int argCount = callExpr.getParameters().size();
        int paramCount = function.getFormalParameters().size();
        if (argCount != paramCount) {
            semanticError("Function '" + functionName + "' expects " + paramCount + " arguments but got " + argCount);
        }

        // Check parameter types
        int count = Math.min(argCount, paramCount);
        for (int i = 0; i < count; i++) {
            Type argType = getType(callExpr.getParameters().get(i));
            Type paramType = function.getFormalParameters().get(i).getType();

            if (!typesAreCompatible(paramType, argType)) {
                semanticError("Type mismatch for parameter " + (i + 1) + " in call to '" + functionName
                        + "': expected " + paramType + ", got " + argType);
            }
        }

        // Set type of call expression to function's return type
        setType(callExpr, function.getReturnType());
    }

    @Override
    public void visit(UnaryExpression expr) {
        expr.getExpression().accept(this);
        Type operandType = getType(expr.getExpression());
        UnaryOperator op = expr.getUnaryOperator();

        // Check operator applicability and determine result type
        Type resultType;
        if (op == UnaryOperator.NOT) {
            if (operandType instanceof BooleanType) {
                resultType = new BooleanType();
            } else {
                semanticError("Operator '!' not applicable to type " + operandType);
                resultType = new VoidType();
            }
        } else if (op == UnaryOperator.MINUS) {
            if (operandType instanceof IntegerType) {
                resultType = new IntegerType();
            } else {
                semanticError("Operator '" + op + "' not applicable to type " + operandType);
                resultType = new VoidType();
            }
        } else if (op == UnaryOperator.PRE_INCREMENT || op == UnaryOperator.PRE_DECREMENT
                || op == UnaryOperator.POST_INCREMENT || op == UnaryOperator.POST_DECREMENT) {
            if (operandType instanceof IntegerType && isAssignable(expr.getExpression())) {
                resultType = new IntegerType();
            } else {
                semanticError("Operator '" + op + "' not applicable to type " + operandType);
                resultType = new VoidType();
            }
        } else {
            semanticError("Unknown unary operator: " + op);
            resultType = new VoidType();
        }

        setType(expr, resultType);
    }

    @Override
    public void visit(BinaryExpression expr) {
        expr.getLeft().accept(this);
        expr.getRight().accept(this);

        Type leftType = getType(expr.getLeft());
        Type rightType = getType(expr.getRight());
        BinaryOperator op = expr.getBinaryOperator();

        // Check operator applicability and determine result type
        Type resultType;

        if (leftType.equals(rightType)) {
            switch (leftType) {
                case IntegerType integerType -> resultType = switch (op) {
                    case PLUS, MINUS, TIMES, DIV, MOD -> new IntegerType();
                    case EQUAL, UNEQUAL, LESSER, LESSER_EQ, GREATER, GREATER_EQ -> new BooleanType();
                    default -> {
                        semanticError("Operator '" + op + "' not applicable to type " + leftType);
                        yield new VoidType();
                    }
                };
                case BooleanType booleanType -> resultType = switch (op) {
                    case AND, OR, EQUAL, UNEQUAL -> new BooleanType();
                    default -> {
                        semanticError("Operator '" + op + "' not applicable to type " + leftType);
                        yield new VoidType();
                    }
                };
                case StringType stringType -> resultType = switch (op) {
                    case PLUS ->
                        // Assuming string concatenation
                            new StringType();
                    case EQUAL, UNEQUAL, LESSER, LESSER_EQ, GREATER, GREATER_EQ ->
                        // Relational comparisons are acceptable for strings
                            new BooleanType();
                    default -> {
                        semanticError("Operator '" + op + "' not applicable to type " + leftType);
                        yield new VoidType();
                    }
                };
                default -> {
                    semanticError("Operator '" + op + "' not applicable to type " + leftType);
                    resultType = new VoidType();
                }
            }
        } else {
            semanticError("Type mismatch in binary expression: " + leftType + " and " + rightType);
            resultType = new VoidType();
        }

        setType(expr, resultType);
    }

    @Override
    public void visit(FieldAccess fieldAccess) {
        // Visit the base expression
        fieldAccess.getBase().accept(this);
        Type baseType = getType(fieldAccess.getBase());

        if (baseType instanceof RecordType recordType) {
            Struct struct = structs.get(recordType.getIdentifier());
            if (struct == null) {
                semanticError("Undefined struct type: " + recordType.getIdentifier());
                setType(fieldAccess, new VoidType());
            } else {
                Declaration fieldDecl = null;
                for (Declaration field : struct.getDeclarations()) {
                    if (field.getIdentifier().equals(fieldAccess.getField())) {
                        fieldDecl = field;
                        break;
                    }
                }
                if (fieldDecl == null) {
                    semanticError("Field '" + fieldAccess.getField() + "' not found in struct '"
                            + recordType.getIdentifier() + "'");
                    setType(fieldAccess, new VoidType());
                } else {
                    setType(fieldAccess, fieldDecl.getType());
                }
            }
        } else {
            semanticError("Type '" + baseType + "' is not a struct");
            setType(fieldAccess, new VoidType());
        }
    }

    @Override
    public void visit(ArrayAccess arrayAccess) {
        // Visit the base array expression and the index expression
        arrayAccess.getBase().accept(this);
        arrayAccess.getIndexExpression().accept(this);

        Type baseType = getType(arrayAccess.getBase());
        Type indexType = getType(arrayAccess.getIndexExpression());

        if (!(baseType instanceof ArrayType)) {
            semanticError("Type '" + baseType + "' is not an array");
            setType(arrayAccess, new VoidType());
        } else if (!(indexType instanceof IntegerType)) {
            semanticError("Array index must be of type integer");
            setType(arrayAccess, new VoidType());
        } else {
            // Set the type of the array access to the element type
            Type elementType = ((ArrayType) baseType).getType();
            setType(arrayAccess, elementType);
        }
    }

    @Override
    public void visit(IfStatement ifStmt) {
        ifStmt.getExpression().accept(this);
        Type condType = getType(ifStmt.getExpression());

        if (!(condType instanceof BooleanType)) {
            semanticError("Condition in if statement must be of type boolean");
        }

        // Visit then statements
        for (Statement stmt : ifStmt.getStatements()) {
            stmt.accept(this);
        }

        // Visit else clause if present
        if (ifStmt.getElseBlock() != null) {
            for (Statement stmt : ifStmt.getElseBlock().getStatements()) {
                stmt.accept(this);
            }
        }
    }

    @Override
    public void visit(WhileStatement whileStmt) {
        whileStmt.getExpression().accept(this);
        Type condType = getType(whileStmt.getExpression());

        if (!(condType instanceof BooleanType)) {
            semanticError("Condition in while statement must be of type boolean");
        }

        // Visit body statements
        for (Statement stmt : whileStmt.getStatements()) {
            stmt.accept(this);
        }
    }

    @Override
    public void visit(ReturnStatement returnStmt) {
        if (currentFunction == null) {
            semanticError("Return statement outside of a function");
            return;
        }

        Type expectedType = currentFunction.getReturnType();
        Expression expr = returnStmt.getExpression();

        if (expr != null) {
            expr.accept(this);
            Type actualType = getType(expr);

            if (expectedType instanceof VoidType) {
                semanticError("Return statement with a value in a void function");
            } else if (!typesAreCompatible(expectedType, actualType)) {
                semanticError("Type mismatch in return statement: expected " + expectedType + ", got " + actualType);
            }
        } else {
            if (!(expectedType instanceof VoidType)) {
                semanticError("Return statement missing a value in function returning " + expectedType);
            }
        }
    }

    @Override
    public void visit(Block block) {
        // Start a new scope
        Map<String, Declaration> blockScope = new HashMap<>();
        scopes.push(blockScope);

        // Visit statements
        for (Statement stmt : block.getStatements()) {
            stmt.accept(this);
        }

        // End scope
        scopes.pop();
    }

    private boolean isValidType(Type type) {
        if (type instanceof IntegerType || type instanceof BooleanType || type instanceof StringType) {
            return true;
        } else if (type instanceof ArrayType) {
            return isValidType(((ArrayType) type).getType());
        } else if (type instanceof RecordType) {
            String typeName = ((RecordType) type).getIdentifier();
            return structs.containsKey(typeName);
        } else {
            return false;
        }
    }

    // Helper method to get built-in functions
    private Function getBuiltInFunction(String name) {
        return switch (name) {
            case "writeInt" -> new Function(
                    "writeInt",
                    new VoidType(),
                    Collections.singletonList(new Declaration("i", new IntegerType(), false)),
                    Collections.emptyList()
            );
            case "readInt" -> new Function(
                    "readInt",
                    new IntegerType(),
                    Collections.emptyList(),
                    Collections.emptyList()
            );
            case "writeChar" -> new Function(
                    "writeChar",
                    new VoidType(),
                    Collections.singletonList(new Declaration("c", new IntegerType(), false)),
                    Collections.emptyList()
            );
            case "readChar" -> new Function(
                    "readChar",
                    new IntegerType(),
                    Collections.emptyList(),
                    Collections.emptyList()
            );
            default -> null;
        };
    }
}
