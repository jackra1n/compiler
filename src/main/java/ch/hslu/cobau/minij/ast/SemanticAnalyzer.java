package ch.hslu.cobau.minij.ast;

import ch.hslu.cobau.minij.ast.constants.IntegerConstant;
import ch.hslu.cobau.minij.ast.constants.*;
import ch.hslu.cobau.minij.ast.entity.*;
import ch.hslu.cobau.minij.ast.expression.*;
import ch.hslu.cobau.minij.ast.statement.*;
import ch.hslu.cobau.minij.ast.type.*;

import java.util.*;

public class SemanticAnalyzer extends BaseAstVisitor {
    // Global symbol table for functions, globals, and structs
    private final Map<String, Declaration> globalVariables = new HashMap<>();
    private final Map<String, Function> functions = new HashMap<>();
    private final Map<String, Struct> structs = new HashMap<>();

    // Stack to manage scopes
    private final Deque<Map<String, Declaration>> scopes = new ArrayDeque<>();

    // Current function being analyzed
    private Function currentFunction = null;

    // List to collect semantic errors
    private final List<String> errors = new ArrayList<>();

    public boolean analyze(Unit unit) {
        // Start analysis by visiting the unit
        visit(unit);
        // Return true if no errors were found
        return errors.isEmpty();
    }

    private void semanticError(String message) {
        errors.add(message);
        System.err.println("Semantic Error: " + message);
    }

    // Other methods to access errors, if needed
    public List<String> getErrors() {
        return errors;
    }

    // Visitor methods
    @Override
    public void visit(Unit unit) {
        // Visit structs first to ensure they are available when needed
        for (Struct struct : unit.getStructs()) {
            struct.accept(this);
        }

        // Visit global variable declarations
        for (Declaration global : unit.getGlobals()) {
            global.accept(this);
        }

        // Visit function declarations
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
            // Check for duplicate field names within the struct
            Set<String> fieldNames = new HashSet<>();
            for (Declaration field : struct.getDeclarations()) {
                String fieldName = field.getIdentifier();
                if (!fieldNames.add(fieldName)) {
                    semanticError("Duplicate field name '" + fieldName + "' in struct '" + name + "'");
                } else if (field.getType() instanceof VoidType) {
                    semanticError("Struct field '" + fieldName + "' cannot be of type void");
                }
            }
            structs.put(name, struct);
        }
    }

    @Override
    public void visit(Declaration declaration) {
        String name = declaration.getIdentifier();
        Type type = declaration.getType();
        if (currentFunction == null) {
            // Global variable declaration
            if (globalVariables.containsKey(name)) {
                semanticError("Duplicate global variable declaration: " + name);
            } else if (type instanceof VoidType) {
                semanticError("Global variable '" + name + "' cannot be of type void");
            } else {
                globalVariables.put(name, declaration);
            }
        } else {
            // Local variable declaration
            Map<String, Declaration> currentScope = scopes.peek();
            if (currentScope.containsKey(name)) {
                semanticError("Duplicate local variable declaration: " + name);
            } else if (type instanceof VoidType) {
                semanticError("Local variable '" + name + "' cannot be of type void");
            } else {
                currentScope.put(name, declaration);
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
        scopes.push(new HashMap<>());
        currentFunction = function;

        // Add formal parameters to the scope
        Set<String> parameterNames = new HashSet<>();
        for (Declaration param : function.getFormalParameters()) {
            String paramName = param.getIdentifier();
            if (!parameterNames.add(paramName)) {
                semanticError("Duplicate parameter name '" + paramName + "' in function '" + name + "'");
            } else if (param.getType() instanceof VoidType) {
                semanticError("Function parameter '" + paramName + "' cannot be of type void");
            } else {
                scopes.peek().put(paramName, param);
            }
        }

        // Visit the function body (statements)
        function.visitChildren(this);

        // Clean up
        scopes.pop();
        currentFunction = null;
    }

    @Override
    public void visit(DeclarationStatement declarationStmt) {
        // Visit the declaration within the statement
        declarationStmt.getDeclaration().accept(this);
    }

    @Override
    public void visit(AssignmentStatement assignment) {
        // Visit the left-hand side and right-hand side expressions
        assignment.getLeft().accept(this);
        assignment.getRight().accept(this);

        // Get the types of the left and right expressions
        Type leftType = getType(assignment.getLeft());
        Type rightType = getType(assignment.getRight());

        // Check if the left expression is assignable
        if (!isAssignable(assignment.getLeft())) {
            semanticError("Left-hand side of assignment must be a variable, field access, or array access");
            return;
        }

        // Check if the types are compatible
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
            varAccess.setType(new VoidType()); // Set to void to avoid cascading errors
        } else {
            varAccess.setType(declaration.getType());
        }
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
                setType(callExpr, new VoidType()); // Set to void to prevent cascading errors
                return;
            }
        }

        // Visit all actual parameters
        List<Expression> arguments = callExpr.getParameters();
        for (Expression arg : arguments) {
            arg.accept(this);
        }

        // Get the formal parameters
        List<Declaration> formalParameters = function.getFormalParameters();

        // Check the number of parameters
        if (arguments.size() != formalParameters.size()) {
            semanticError("Function '" + functionName + "' expects " + formalParameters.size()
                    + " arguments but got " + arguments.size());
        }

        // Check the types of parameters
        int numParams = Math.min(arguments.size(), formalParameters.size());
        for (int i = 0; i < numParams; i++) {
            Type argType = getType(arguments.get(i));
            Type paramType = formalParameters.get(i).getType();

            if (!typesAreCompatible(paramType, argType)) {
                semanticError("Type mismatch for parameter " + (i + 1) + " in call to '" + functionName
                        + "': expected " + paramType + ", got " + argType);
            }
        }

        // Set the type of the call expression to the function's return type
        setType(callExpr, function.getReturnType());
    }

    // Helper methods
    private final Map<Expression, Type> expressionTypes = new HashMap<>();

    // Methods to get and set expression types
    private void setType(Expression expr, Type type) {
        expressionTypes.put(expr, type);
    }

    private Type getType(Expression expr) {
        Type type = expressionTypes.get(expr);
        if (type == null) {
            // If the type is not set, we can return a special type or handle it accordingly
            // For now, we'll return a VoidType to prevent null pointers
            return new VoidType();
        }
        return type;
    }


    private Declaration lookupVariable(String name) {
        // Check local scopes first
        for (Map<String, Declaration> scope : scopes) {
            if (scope.containsKey(name)) {
                return scope.get(name);
            }
        }
        // Then global variables
        return globalVariables.get(name);
    }

    private boolean isAssignable(Expression expr) {
        return expr instanceof VariableAccess || expr instanceof FieldAccess || expr instanceof ArrayAccess;
    }


    private boolean typesAreCompatible(Type expected, Type actual) {
        // Implement type compatibility logic
        // For simplicity, we'll use equals method
        return expected.equals(actual);
    }

    private Function getBuiltInFunction(String name) {
        // Return the built-in function if it exists
        switch (name) {
            case "writeInt":
                return new Function("writeInt", new VoidType(), Collections.singletonList(new Declaration("i", new IntegerType(), false)), null);
            case "readInt":
                return new Function("readInt", new IntegerType(), Collections.emptyList(), null);
            case "writeChar":
                return new Function("writeChar", new VoidType(), Collections.singletonList(new Declaration("c", new IntegerType(), false)), null);
            case "readChar":
                return new Function("readChar", new IntegerType(), Collections.emptyList(), null);
            default:
                return null;
        }
    }

}
