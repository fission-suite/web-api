-- | Setup command
module Fission.CLI.Handler.User.Register (register) where

import qualified Crypto.PubKey.Ed25519           as Ed25519
import qualified Crypto.PubKey.RSA               as RSA
import           Crypto.Random

import           Network.DNS
import           Network.HTTP.Types.Status

import           Servant.API
import           Servant.Client

import           Fission.Prelude

import           Fission.Error
import qualified Fission.Key                     as Key

import           Fission.Authorization.ServerDID
import           Fission.User.DID.Types
import           Fission.User.Username.Types

import           Fission.Web.Auth.Token
import           Fission.Web.Client              as Client
import qualified Fission.Web.Client.User         as User

import           Fission.User.Email.Types
import           Fission.User.Registration.Types
import qualified Fission.User.Username.Types     as User

import           Fission.CLI.Key.Store           as KeyStore

import           Fission.CLI.Display.Error       as CLI.Error
import           Fission.CLI.Display.Success     as CLI.Success

import           Fission.CLI.Environment         as Env
import qualified Fission.CLI.Prompt              as Prompt

register ::
  ( MonadIO          m
  , MonadLogger      m
  , MonadWebClient   m
  , MonadEnvironment m
  , MonadTime        m
  , MonadRandom      m
  , ServerDID        m
  , MonadWebAuth     m Token
  , MonadWebAuth     m Ed25519.SecretKey
  , MonadCleanup     m
  , m `Raises` ClientError
  , m `Raises` DNSError
  , m `Raises` NotFound DID
  , m `Raises` AlreadyExists Ed25519.SecretKey
  , IsMember ClientError (Errors m)
  , IsMember Key.Error   (Errors m)
  , Show (OpenUnion (Errors m))
  )
  => m Username
register =
  attempt (sendRequestM . authClient $ Proxy @User.WhoAmI) >>= \case
    Right un@User.Username {username} -> do
      CLI.Success.alreadyLoggedInAs username
      return un

    Left _ ->
      createAccount

createAccount ::
  ( MonadIO          m
  , MonadLogger      m
  , MonadEnvironment m
  , MonadWebClient   m
  , MonadTime        m
  , ServerDID        m
  , MonadRandom      m
  , MonadWebAuth     m Token
  , MonadWebAuth     m Ed25519.SecretKey
  , MonadCleanup     m
  , IsMember ClientError (Errors m)
  , IsMember Key.Error   (Errors m)
  , m `Raises` ClientError
  , m `Raises` DNSError
  , m `Raises` NotFound DID
  , m `Raises` AlreadyExists Ed25519.SecretKey
  , Show (OpenUnion (Errors m))
  )
  => m Username
createAccount = do
  username <- Username <$> Prompt.reaskNotEmpty' "Username: "
  email    <- Email    <$> Prompt.reaskNotEmpty' "Email: "

  let
    form = Registration
      { username
      , email
      , password = Nothing
      }

  attempt (sendRequestM $ authClient (Proxy @User.Register) `withPayload` form) >>= \case
    Left err -> do
      let msg = registerErrMsg err
      CLI.Error.put msg $
        msg <> " Please try again or contact Fission support at https://fission.codes"

      createAccount

    Right _ok -> do
      CLI.Success.putOk "Registration successful! Head over to your email to confirm your account."

      -- FIXME move to own module
      exchangeSK <- KeyStore.fetch $ Proxy @ExchangeKey
      exchangePK <- KeyStore.toPublic (Proxy @ExchangeKey) exchangeSK

      attempt (sendRequestM (getAddExchangePKClient `withPayload` exchangePK)) >>= \case
        Left _ -> undefined
        Right _ -> undefined

      return username

registerErrMsg :: IsMember ClientError errs => OpenUnion errs -> Text
registerErrMsg err =
  case openUnionMatch err of
    Nothing ->
      "Unknown Error"

    Just respErr ->
      case respErr of
        FailureResponse _ (responseStatusCode -> status) ->
          if | status == status409 ->
                "It looks like that account already exists."

              | statusIsClientError status ->
                "There was a problem with your request."

              | otherwise ->
                "There was a server error."

        ConnectionError _ ->
          "Trouble contacting the server."

        DecodeFailure _ _ ->
          "Trouble decoding the registration response."

        _ ->
          "Invalid content type."

-- FIXME put in better module
getAddExchangePKClient ::
  ( MonadIO      m
  , MonadTime    m
  , MonadLogger  m
  , ServerDID    m
  , MonadWebAuth m Token
  , MonadWebAuth m Ed25519.SecretKey
  )
  => m (RSA.PublicKey -> ClientM [RSA.PublicKey])
getAddExchangePKClient = do
  (addExchangeKey :<|> _) <- authClient $ Proxy @User.ExchangeKeysAPI
  return addExchangeKey

