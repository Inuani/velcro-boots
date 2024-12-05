// auth.js
import { AuthClient } from "@dfinity/auth-client";
import { actor, updateActorIdentity } from './actor.js';

export class Auth {
  constructor() {
    this.currentActor = actor;
    this.authClient = null;
  }

  updatePrincipalDisplay = async (isAuthenticated = false) => {
    const displayElement = document.getElementById('principal-display');
    if (displayElement) {
      try {
        const principal = await this.currentActor.whoAmI();
        const principalText = principal.toText();
        displayElement.textContent = `${principalText}`;
      } catch (error) {
        console.error("Error getting principal:", error);
        displayElement.textContent = "Error fetching principal";
      }
    }
  };

  updateAuthButton = (isAuthenticated) => {
    const button = document.getElementById('auth-button');
    if (button) {
      button.textContent = isAuthenticated ? 'Sign Out' : '✨ Sign in for Magic ✨';
    }
  };

  handleAuthenticated = async (authClient) => {
    const identity = authClient.getIdentity();
    this.currentActor = updateActorIdentity(identity);
    await this.updatePrincipalDisplay(true);
    this.updateAuthButton(true);
  };

  setupAuthButton = () => {
    document.getElementById('auth-button')?.addEventListener('click', async () => {
      if (!this.authClient) return;

      if (await this.authClient.isAuthenticated()) {
        // Sign out
        await this.authClient.logout();
        this.currentActor = actor;  // Reset to default actor
        await this.updatePrincipalDisplay(false);
        this.updateAuthButton(false);
      } else {
        // Sign in
        try {
          await new Promise((resolve, reject) => {
            if (!this.authClient) return;
            
            this.authClient.login({
              identityProvider: process.env.DFX_NETWORK === "ic" 
                ? "https://identity.ic0.app"
                : `http://rdmx6-jaaaa-aaaaa-aaadq-cai.localhost:4943`,
              onSuccess: resolve,
              onError: (error) => {
                console.log("Login error:", error);
                reject(error);
              },
              windowOpenerFeatures: `
                width=400,
                height=500,
                left=${window.screen.width / 2 - 200},
                top=${window.screen.height / 2 - 250},
                toolbar=0,
                location=0,
                menubar=0,
                status=0
              `.replace(/\s/g, ''),
            });
          }).catch((error) => {
            // Handle user cancellation or other authentication errors
            if (error?.message === "UserInterrupt") {
              return;
            }
          });

          // Only proceed with authentication if we have a valid authClient state
          if (await this.authClient.isAuthenticated()) {
            await this.handleAuthenticated(this.authClient);
          }
        } catch (error) {
          this.updateAuthButton(false);
        }
      }
    });
  };

  init = async () => {
    this.authClient = await AuthClient.create();
    
    if (await this.authClient.isAuthenticated()) {
      await this.handleAuthenticated(this.authClient);
    } else {
      await this.updatePrincipalDisplay(false);
      this.updateAuthButton(false);
    }

    this.setupAuthButton();
  };

  getCurrentActor = () => this.currentActor;
}