{-# LANGUAGE FlexibleContexts #-}

module Check where

  import Control.Monad.State
  import Control.Monad.Except

  import CommandAST
  import Environment
  import State (initCheckEnvList)
  import Monads

  check :: Comm -> Either String ()
  check (Comm _ []) = Left "Warning" -- TODO
  check (Comm p c)  = let s = envFromList $ initCheckEnvList ++ p
                      in runChecker (checkStmts c) s

  checkStmts :: (Monad m, MonadError String m, MonadState (Env Type) m) => [Statement] -> m ()
  checkStmts = mapM_ checkStmt

  checkStmt :: (Monad m, MonadError String m, MonadState (Env Type) m) => Statement -> m ()
  checkStmt (Declaration v e) = do  s <- get
                                    t <- inferExpr e
                                    case lookUp v s of
                                      Just _  -> raise "Error" -- TODO
                                      Nothing -> put (update (v,t) s)
  checkStmt (Assign v e) = do s <- get
                              t <- inferExpr e
                              case lookUp v s of
                                Just t' ->  case (t', t) of
                                              (Undefined, _) -> return ()
                                              (_, Undefined) -> return ()
                                              _              -> if t == t'
                                                                then return ()
                                                                else raise "Error" -- TODO
                                Nothing -> raise "Error" -- TODO
  checkStmt (If e stmts) = do t <- inferExpr e
                              case t of
                                Undefined -> checkStmts stmts
                                Bool      -> checkStmts stmts
                                _         -> raise "Error" -- TODO
  checkStmt (IfElse e stmts stmts') = do  t <- inferExpr e
                                          s <- get
                                          case t of
                                            Undefined -> do checkStmts stmts
                                                            put s
                                                            checkStmts stmts'
                                                            put s
                                            Bool      -> do checkStmts stmts
                                                            put s
                                                            checkStmts stmts'
                                                            put s
                                            _         -> raise "Error" -- TODO
  checkStmt (While e stmts) = do  t <- inferExpr e
                                  case t of
                                    Undefined -> checkStmts stmts
                                    Bool      -> checkStmts stmts
                                    _         -> raise "Error" -- TODO
  checkStmt (Do stmts e) = do t <- inferExpr e
                              case t of
                                Undefined -> checkStmts stmts
                                Bool      -> checkStmts stmts
                                _         -> raise "Error" -- TODO

  inferExpr :: (Monad m, MonadError String m, MonadState (Env Type) m) => Expr -> m Type
  inferExpr TrueExp = return Bool
  inferExpr FalseExp = return Bool
  inferExpr (Var var) = do  s <- get
                            case lookUp var s of
                              Just t  -> return t
                              Nothing -> raise "Error" -- TODO
  inferExpr (Const _) = return Number
  inferExpr (Str _) = return String
  inferExpr (Not b) = do  t <- inferExpr b
                          case t of
                            Undefined -> return Bool
                            Bool      -> return Bool
                            _         -> raise "Error" -- TODO
  inferExpr (And b0 b1) = do  t0 <- inferExpr b0
                              t1 <- inferExpr b1
                              case (t0, t1) of
                                (Undefined, _)  -> return Bool
                                (_, Undefined)  -> return Bool
                                (Bool, Bool)    -> return Bool
                                _               -> raise "Error" -- TODO
  inferExpr (Or b0 b1) = do t0 <- inferExpr b0
                            t1 <- inferExpr b1
                            case (t0, t1) of
                              (Undefined, _)  -> return Bool
                              (_, Undefined)  -> return Bool
                              (Bool, Bool)    -> return Bool
                              _               -> raise "Error" -- TODO
  inferExpr (Equals n0 n1) = do t0 <- inferExpr n0
                                t1 <- inferExpr n1
                                case (t0, t1) of
                                  (Undefined, _)    -> return Bool
                                  (_, Undefined)    -> return Bool
                                  (Number, Number)  -> return Bool
                                  _                 -> raise "Error" -- TODO
  inferExpr (Greater n0 n1) = do  t0 <- inferExpr n0
                                  t1 <- inferExpr n1
                                  case (t0, t1) of
                                    (Undefined, _)    -> return Bool
                                    (_, Undefined)    -> return Bool
                                    (Number, Number)  -> return Bool
                                    _                 -> raise "Error" -- TODO
  inferExpr (Lower n0 n1) = do  t0 <- inferExpr n0
                                t1 <- inferExpr n1
                                case (t0, t1) of
                                  (Undefined, _)    -> return Bool
                                  (_, Undefined)    -> return Bool
                                  (Number, Number)  -> return Bool
                                  _                 -> raise "Error" -- TODO
  inferExpr (GreaterEquals n0 n1) = do  t0 <- inferExpr n0
                                        t1 <- inferExpr n1
                                        case (t0, t1) of
                                          (Undefined, _)    -> return Bool
                                          (_, Undefined)    -> return Bool
                                          (Number, Number)  -> return Bool
                                          _                 -> raise "Error" -- TODO
  inferExpr (LowerEquals n0 n1) = do  t0 <- inferExpr n0
                                      t1 <- inferExpr n1
                                      case (t0, t1) of
                                        (Undefined, _)    -> return Bool
                                        (_, Undefined)    -> return Bool
                                        (Number, Number)  -> return Bool
                                        _                 -> raise "Error" -- TODO
  inferExpr (Negate n) = do t <- inferExpr n
                            case t of
                              Undefined -> return Number
                              Number    -> return Number
                              _         -> raise "Error" -- TODO
  inferExpr (Plus n0 n1) = do t0 <- inferExpr n0
                              t1 <- inferExpr n1
                              case (t0, t1) of
                                (Undefined, _)    -> return Number
                                (_, Undefined)    -> return Number
                                (Number, Number)  -> return Number
                                _                 -> raise "Error" -- TODO
  inferExpr (Minus n0 n1) = do  t0 <- inferExpr n0
                                t1 <- inferExpr n1
                                case (t0, t1) of
                                  (Undefined, _)    -> return Number
                                  (_, Undefined)    -> return Number
                                  (Number, Number)  -> return Number
                                  _                 -> raise "Error" -- TODO
  inferExpr (Multiply n0 n1) = do t0 <- inferExpr n0
                                  t1 <- inferExpr n1
                                  case (t0, t1) of
                                    (Undefined, _)    -> return Number
                                    (_, Undefined)    -> return Number
                                    (Number, Number)  -> return Number
                                    _                 -> raise "Error" -- TODO
  inferExpr (Divide n0 n1) = do t0 <- inferExpr n0
                                t1 <- inferExpr n1
                                case (t0, t1) of
                                  (Undefined, _)    -> return Number
                                  (_, Undefined)    -> return Number
                                  (Number, Number)  -> return Number
                                  _                 -> raise "Error" -- TODO
  inferExpr (Index e0 e1) = do  t0 <- inferExpr e0
                                t1 <- inferExpr e1
                                case (t0, t1) of
                                  (Undefined, _)  -> return Undefined
                                  (_, Undefined)  -> return Undefined
                                  (JSON, String)  -> return Undefined
                                  _               -> raise "Error" -- TODO
  inferExpr (Get e) = do  t <- inferExpr e
                          case t of
                            Undefined -> return JSON
                            String    -> return JSON
                            _         -> raise "Error" -- TODO
  inferExpr (Post e0 e1) = do t0 <- inferExpr e0
                              t1 <- inferExpr e1
                              case (t0, t1) of
                                (Undefined, _)    -> return JSON
                                (_, Undefined)    -> return JSON
                                (JSON, String)    -> return JSON
                                (String, Number)  -> return JSON
                                _                 -> raise "Error" -- TODO
  inferExpr (JsonObject o) =  let l = map snd $ envToList o
                              in do mapM_ inferExpr l
                                    return JSON
  inferExpr (JsonArray l)  = do mapM_ inferExpr l
                                return JSON
