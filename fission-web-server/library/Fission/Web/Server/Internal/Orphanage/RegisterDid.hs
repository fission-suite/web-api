{-# OPTIONS_GHC -fno-warn-orphans #-}

module Fission.Web.Server.Internal.Orphanage.RegisterDid () where

import           Data.Swagger

import           Servant
import           Servant.Swagger

import           Fission.Prelude

import           Fission.Web.API.Auth.Types
import           Fission.Web.Server.Swagger.Auth

instance HasSwagger api => HasSwagger (RegisterDID :> api) where
  toSwagger _ =
    Proxy @api
      |> toSwagger
      |> securityDefinitions .~ SecurityDefinitions [("Fission Auth", fissionSecurity)]
