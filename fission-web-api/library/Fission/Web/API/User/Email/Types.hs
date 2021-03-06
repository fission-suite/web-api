module Fission.Web.API.User.Email.Types (Email) where

import           Fission.Web.API.Prelude

import           Fission.Web.API.User.Email.Verify.Types

import           Fission.Web.API.User.Email.Resend.Types

type Email = "email" :> API

type API
  =    Verify
  :<|> Resend
