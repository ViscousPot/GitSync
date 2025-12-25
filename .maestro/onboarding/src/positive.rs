use crate::Input;

pub fn get_input() -> Input {
    Input {
        before_all: vec!["disable_all_files_access", "clear_state"],
        before_each: vec![],
        flows: vec![vec![vec![vec![
            "launch_stls_no_perms",
            "legacy_user_dialog/positive",
            "welcome_dialog/positive",
            "notifications_dialog/positive",
            "notifications_permission/enable",
            "all_files_dialog/positive",
            "all_files_permission/enable",
            "almost_there_dialog/positive",
            "pre_auth_dialog/positive",
            "../auth/flows/github/start",
            "../auth/flows/github/assert",
            "../auth/flows/github/auth",
            // "author_details_prompt/positive",
            // "../settings/flows/assert",
            // "../settings/flows/author_name/positive",
            // "../settings/flows/author_email/positive",l
            // "back",
            "../clone/flows/assert",
            "../clone/flows/list/github",
            "../clone/flows/select_folder_dialog/positive",
            "../clone/flows/select_folder/positive",
            "../clone/flows/select_folder/assert_not",
            "../clone/flows/select_folder_dialog/assert_not",
            "showcase/positive",
            "showcase/positive",
            "showcase/positive",
            "showcase/positive",
            "showcase/positive",
            "showcase/positive",
            "showcase/finish",
            "../home/flows/sync_now/assert",
        ]]]],
    }
}
