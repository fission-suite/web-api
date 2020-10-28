module Fission.Web.User.DataRoot.Update
  ( API
  , server
  ) where

import           Database.Esqueleto
import           Servant

import           Fission.Prelude

import           Fission.Config.Types

import qualified Fission.Authorization                      as Authorization
import           Fission.Web.Auth.Token.UCAN.Resource.Types

import qualified Fission.User                               as User
import           Fission.Web.Error                          as Web.Error

import           Network.IPFS.CID.Types


type API
  =  Summary "Update data root"
  :> Description "Set/update currently authenticated user's file system content"
  :> Capture "newCID" CID
  :> PatchNoContent '[PlainText, OctetStream, JSON] NoContent

server ::
  ( MonadLogger     m
  , MonadThrow      m
  , MonadTime       m
  , User.Modifier   m
  )
  => Authorization.Session
  -> ServerT API m
server session newCID = do
  cfg <- ask
  sessionVar <- atomically $ newTVar session

  -- FIXME maybe an "updateExtended" or "extendConfig" typeclass?
  Fission . RIO . withReaderT (cfg & extended .~ sessionVar) unRIO $ unFission do
  -- server Authorization {about = Entity userID _} newCID = do
    let userID = undefined -- FIXME
    now <- currentTime
    Web.Error.ensureM $ User.setData userID newCID now
    return NoContent

-- FIXME generalize with a typeclass
withSession ::
     Authorization.Session
  -> Fission (TVar Authorization.Session) a
  -> Fission extCfg a
withSession session action = do
  cfg        <- ask
  sessionVar <- atomically $ newTVar session

  -- FIXME maybe an "updateExtended" or "extendConfig" typeclass?
  Fission . RIO . withReaderT (cfg & extended .~ sessionVar) unRIO $ unFission action
