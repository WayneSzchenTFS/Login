//
//  ContentView.swift
//  Login
//
//  Created by Wayne Chen on 2023-05-30.
//

import SwiftUI
import Firebase
import FirebaseStorage

struct LoginView: View {
    @State private var sheetIsPresented = false
    //@Environment(\.dismiss) private var dismiss


    
    @State var isLoginMode = false
     @State var email = ""
     @State var password = ""
     
    
    @State var shouldShowImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    
                    VStack(spacing: 16) {
                        // Sélecteur pour le mode de connexion
                        Picker(selection: $isLoginMode, label: Text("Picker here")) {
                            Text("Se connecter")
                                .tag(true) //rassurer que ceci est choisi en premier
                            Text("Créer un compte")
                                .tag(false)
                        }.pickerStyle(SegmentedPickerStyle())  //séparer en 2 colonnes et rendre plus organiséee
                        
                        if !isLoginMode {
                            // Bouton pour afficher la sélection d'image
                            Button {
                                shouldShowImagePicker.toggle()
                            } label: {
                                
                                VStack {
                                    if let image = self.image {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 128, height: 128)
                                            .cornerRadius(64)
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 64))
                                            .padding()
                                            .foregroundColor(Color(.label))
                                    }
                                }
                                .overlay(RoundedRectangle(cornerRadius: 64)
                                    .stroke(Color.black, lineWidth: 3)
                                )
                                
                            }
                        }
                        
                        Group {      //modifier le text de l'usager pour email
                            // Champ de saisie pour l'adresse e-mail
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                            // facilite la tache pour l'usager avec un keyboard qui incluent @
                                .autocapitalization(.none)
                            // Champ de saisie pour le mot de passe
                            SecureField("Mot de passe", text: $password) //pour plus de sécurité
                        
                            
                        }
                        .padding(12)
                        .background(Color.white)
                        
                        ScrollView {
                            VStack {// titre
                                Text("Bienvenue dans notre application familiale !")
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                //description de l'application sur l'inteface
                                Text("Cette application vous permet de créer des comptes familiaux et de partager vos souvenirs préférés avec votre famille. Vous pouvez stocker des informations telles que le nom, l'âge, la relation familiale et le souvenir familial préféré de chaque membre de la famille. Profitez de cette plateforme pour renforcer les liens familiaux et créer des souvenirs durables.")
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .padding()
                        }
                        
                        // Bouton de connexion ou de création de compte
                        Button {
                            handleAction()
                            
                            
                        } label: {
                            HStack {
                                Spacer()
                                Text(isLoginMode ? "Se connecter" : "Créer un compte")
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                            }.background(Color.blue)
                            
                        }
                        
                        // Message d'état de la connexion
                        Text(self.loginStatusMessage)
                            .foregroundColor(.red)
                    }
                    .padding()
                    
                }
                .navigationTitle(isLoginMode ? "Se connecter" : "Créer un compte")
                .background(Color(.init(white: 0, alpha: 0.05))
                    .ignoresSafeArea())
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
                ImagePicker(image: $image)
            }

        }
        .fullScreenCover(isPresented: $sheetIsPresented) {
            SaveDetailView(spot: LoginSaveModel())
        }
    }
    
    @State var image: UIImage?
    
    private func handleAction() {
        if isLoginMode {
            // Connexion de l'utilisateur existant à Firebase avec les informations d'identification fournies
            loginUser()
            //1. self.isLoggedIn = true

            sheetIsPresented.toggle()
            
            /* Code précédente, ne fonction pas trop
            List {
                Text("List items will go here")
            }
            .listStyle(.plain)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") {
                        do {
                            try Auth.auth().signOut()
                            print("Succesfull")
                            dismiss()
                        }catch {
                            print("error")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        sheetIsPresented.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
              .sheet(isPresented: $sheetIsPresented) {
                  NavigationStack {
                      SaveDetailView(spot: LoginSaveModel())
                  }
              }
              */
        } else {
            // Création d'un nouveau compte utilisateur dans Firebase Auth, puis stockage de l'image dans Storage
            createNewAccount()
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Erreur dans la connexion de l'utilisateur", err)
                self.loginStatusMessage = "Erreur dans la connexion de l'utilisateur: \(err)"
                return
            }
            
            print("Connexion réussie en tant qu'utilisateur: \(result?.user.uid ?? "")")
            //Je veux que ceci apparait quand on se connecte mais ça ne fonctionne pas
            MainMessagesView()
            self.loginStatusMessage = "Connexion réussie en tant qu'utilisateur: \(result?.user.uid ?? "")"
            
        }
    }
    
    @State var loginStatusMessage = ""
    
    private func createNewAccount() { //crée un compte, affiche un message si ça ne fonctionne pas
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Erreur dans la création de l'utilisateur:", err)
                self.loginStatusMessage = "Erreur dans la création de l'utilisateur: \(err)"
                return
            }
            
            print("Création réussie d'un utilisateur: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "Création réussie d'un utilisateur: \(result?.user.uid ?? "")"
            
            self.persistImageToStorage()
        }
    }
    
    private func persistImageToStorage() {
        // Récupérer l'ID utilisateur unique (UID)
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        // Créer une référence au chemin de stockage de l'image
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        // Vérifier si les données de l'image existent et les convertir en format JPEG avec une qualité de compression de 0.5
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        // Stocker les données de l'image dans Storage
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "Echoué dans l'envoi de l'image: \(err)"
                return
            }
            
            // Récupérer l'URL de téléchargement de l'image
            ref.downloadURL { url, err in
                if let err = err {
                    self.loginStatusMessage = "Échec de la récupération du downloadURL: \(err)"
                    return
                }
                
                self.loginStatusMessage = "Image envoyée avec succès avec l'url: \(url?.absoluteString ?? "")"
                print(url?.absoluteString)
            }
        }
    }
}

