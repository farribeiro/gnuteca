<?php
class MAuthDb extends MAuth
{
    public function authenticate($userId, $pass)
    {
        $pass = md5($pass);
        $this->manager->logMessage("[LOGIN] Authenticating $userId");
        $login = NULL;

        try
        {
            $user = $this->manager->getBusinessMAD('user');
            $user->getByLoginPass($userId, $pass);

            if ($user->login)
            {
                $login = new MLogin($user);
                if ($this->manager->getConf("options.dbsession"))
                {
                    $session = $this->manager->getBusinessMAD('session');
                    $session->lastAccess($login);
                    $session->registerIn($login);
                }

                $this->setLogin($login);
                $this->manager->logMessage("[LOGIN] Authenticated $userId");
            }
            else
            {
                $this->manager->logMessage("[LOGIN] $userId NOT Authenticated");
            }
        }
        catch( Exception $e )
        {
            $this->manager->logMessage("[LOGIN] $userId NOT Authenticated - " . $e->getMessage());
        }

        return $login;
    }
}
?>
