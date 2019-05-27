-- TO DO: test cases, interp

-- use this to print output after compilation
import Dict exposing (..)
import List exposing (length)
import Html exposing (text)

main =
  text "hello world"


-- type definitions
-- NOTE: on 'custom types' tutorial page, there are two approaches:
-- streamlined type defs (as seen below) or more verbose 'record' based style.
-- downside of streamlined version is you must use case statements to access fields.
type ExprC
  = NumC Float
  | IdC String
  | StringC String
  | IfC ExprC ExprC ExprC
  | LamC (List String) ExprC
  | AppC ExprC (List ExprC)

type Value
  = NumV Float
  | BoolV Bool
  | StringV String
  | PrimV (Value -> Value -> Result String Value)
  | CloV (List String) ExprC Env

type alias Env = (Dict String Value)

topEnv : Env
topEnv = (fromList [("true", (BoolV True)),
                    ("false", (BoolV False)),
                    ("+", (PrimV valAdd)),
                    ("-", (PrimV valSub)),
                    ("*", (PrimV valMult)),
                    ("/", (PrimV valDiv)),
                    ("<=", (PrimV valLeq)),
                    ("equal?", (PrimV valEqual))])


-- top-level functions
interp : ExprC -> Env -> Result String Value
interp e env =
  case e of
    (NumC n) -> (NumV n)
    (StringC str) -> (StringV str)
    (IdC id) -> (lookup id env)
    (IfC testt thenn elsee) ->
      case (interp testt env) of
        (BoolV bool) ->
          if bool
          then (interp thenn env)
          else (interp elsee env)
        _ -> Err "test clause not boolean"
    (LamC params body) -> (CloV params body env)
    (AppC fun args) ->
      case (interp fun env) of
        (PrimV op) ->
          if (length args) == 2
          then (op (interp (head args) env)
                   (interp (tail args) env))
          else Err "primitive operation takes two arguments"
        _ -> Err "not supported"


-- helper functions
lookup : String -> Env -> Result String Value
lookup id env =
  case (get id env) of
    Just val ->
      Ok val
    Nothing -> 
      Err "unbound identifier"


-- primitive operations
valAdd : Value -> Value -> Result String Value
valAdd l r =
  case (l, r) of
    ((NumV lval), (NumV rval)) ->
      Ok (NumV (lval + rval))
    _ ->
      Err "operand not a number"

valSub : Value -> Value -> Result String Value
valSub l r =
  case (l, r) of
    ((NumV lval), (NumV rval)) ->
      Ok (NumV (lval - rval))
    _ ->
      Err "operand not a number"

valMult : Value -> Value -> Result String Value
valMult l r =
  case (l, r) of
    ((NumV lval), (NumV rval)) ->
      Ok (NumV (lval * rval))
    _ ->
      Err "operand not a number"

valDiv : Value -> Value -> Result String Value
valDiv l r =
  case (l, r) of
    ((NumV lval), (NumV rval)) ->
      if rval == 0
      then Err "divide by zero" 
      else Ok (NumV (lval - rval))
    _ ->
      Err "operand not a number"

valLeq : Value -> Value -> Result String Value
valLeq l r =
  case (l, r) of
    ((NumV lval), (NumV rval)) ->
      Ok (BoolV (lval <= rval))
    _ ->
      Err "operand not a number"

valEqual : Value -> Value -> Result String Value
valEqual l r =
  case (l, r) of
    ((NumV lval), (NumV rval)) ->
      Ok (BoolV (lval == rval))
    ((BoolV lval), (BoolV rval)) ->
      Ok (BoolV (lval == rval))
    ((StringV lval), (StringV rval)) ->
      Ok (BoolV (lval == rval))
    _ ->
      Ok (BoolV False)