module Fission.Web.Auth.Token.JWT.Resolver.Class (Resolver (..)) where

import           Network.IPFS.CID.Types

import           Fission.Prelude

import           Fission.Web.Auth.Token.JWT.Resolver.Error
import           Fission.Web.Auth.Token.JWT.Types

import qualified Fission.Web.Auth.Token.JWT.RawContent     as JWT

class Monad m => Resolver m where
  resolve :: CID -> m (Either Error (JWT.RawContent, JWT))
