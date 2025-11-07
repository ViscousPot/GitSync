use std::{env, fs, path::Path, path::PathBuf, sync::Arc, collections::HashMap};
use flutter_rust_bridge::DartFnFuture;
use osshkeys::{KeyPair, KeyType};
use git2::{
    CertificateCheckStatus, Cred,  DiffOptions, ErrorCode,
    FetchOptions, PushOptions, RemoteCallbacks, Repository, RepositoryState, ResetType, Signature,
    StatusOptions, Status, BranchType, Tree, SubmoduleUpdateOptions
};
use ssh_key::{HashAlg, LineEnding, PrivateKey};

pub struct Commit {
    pub timestamp: i64,
    pub author: String,
    pub reference: String,
    pub commit_message: String,
    pub additions: i32,
    pub deletions: i32,
    pub unpulled: bool,
    pub unpushed: bool,
}

pub struct Diff {
    pub files_changed: i32,
    pub insertions: i32,
    pub deletions: i32,
    pub diff_parts: HashMap<String, HashMap<String, String>>,  
}

// Also add to lib/api/logger.dart:21
pub enum LogType {
    Global,
    AccessibilityService,
    Sync,
    GitStatus,
    AbortMerge,
    Diff,
    Commit,
    GetRepos,
    CloneRepo,
    SelectDirectory,
    PullFromRepo,
    PushToRepo,
    ForcePull,
    ForcePush,
    RecentCommits,
    Stage,
    SyncException,
}

pub fn init(homepath: Option<String>) {
    env::set_var("RUST_BACKTRACE", "1");
    flutter_rust_bridge::setup_default_user_utils();

    if let Some(path) = homepath {
        env::set_var("HOME", path);
    }

    // unsafe {
    //     set_verify_owner_validation(false).unwrap();
    // }

    if let Ok(mut config) = git2::Config::open_default() {
        let _ = config.set_str("safe.directory", "*");
    }
}

fn get_default_callbacks<'cb>(
    provider: Option<&'cb String>,
    credentials: Option<&'cb (String, String)>,
) -> RemoteCallbacks<'cb> {
    let mut callbacks = RemoteCallbacks::new();

    callbacks.certificate_check(|_, _| Ok(CertificateCheckStatus::CertificateOk));

    if let (Some(provider), Some(credentials)) = (provider, credentials) {
        callbacks.credentials(move |_url, username_from_url, _allowed_types| {
            if provider == "SSH" {
                Cred::ssh_key_from_memory(
                    username_from_url.unwrap(),
                    None,
                    credentials.1.as_str(),
                    if credentials.0.is_empty() {
                        None
                    } else {
                        Some(credentials.0.as_str())
                    },
                )
            } else {
                Cred::userpass_plaintext(credentials.0.as_str(), credentials.1.as_str())
            }
        });
    }

    callbacks
}

fn set_author(repo: &Repository, author: &(String, String)) {
    let mut config = repo.config().unwrap();
    config.set_str("user.name", &author.0);
    config.set_str("user.email", &author.1);
}

fn _log(
    log: Arc<impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static>,
    log_type: LogType,
    message: String,
) {
    flutter_rust_bridge::spawn(async move {
        log(log_type, message).await;
    });
}

pub async fn get_submodule_paths(path_string: String,) -> Result<Vec<String>, git2::Error> {
    let repo = Repository::open(path_string)?;
    let mut paths = Vec::new();

    for mut submodule in repo.submodules()? {
        submodule.reload(false)?; 
        if let Some(path) = submodule.path().to_str() {
            paths.push(path.to_string());
        }
    }

    Ok(paths)
}

pub async fn clone_repository(
    url: String,
    path_string: String,
    provider: String,
    credentials: (String, String),
    author: (String, String),
    clone_task_callback: impl Fn(String) -> DartFnFuture<()> + Send + Sync + 'static,
    clone_progress_callback: impl Fn(i32) -> DartFnFuture<()> + Send + Sync + 'static,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    init(None);
    let clone_task_callback = Arc::new(clone_task_callback);
    let clone_progress_callback = Arc::new(clone_progress_callback);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::CloneRepo,
        "Cloning Repo".to_string(),
    );

    let mut builder = git2::build::RepoBuilder::new();
    let mut callbacks = get_default_callbacks(Some(&provider), Some(&credentials));

    callbacks.sideband_progress(move |data| {
        if let Ok(text) = std::str::from_utf8(data) {
            let text = text.to_string();
            let callback = Arc::clone(&clone_task_callback);
            flutter_rust_bridge::spawn(async move {
                callback(text).await;
            });
        }
        true
    });

    callbacks.transfer_progress(move |stats| {
        let total = stats.total_objects() as i32;
        let received = stats.indexed_objects() as i32;
        let progress = if total > 0 {
            (received * 100) / total
        } else {
            0
        };
        let callback = Arc::clone(&clone_progress_callback);
        flutter_rust_bridge::spawn(async move {
            callback(progress).await;
        });
        true
    });

    let mut fo = FetchOptions::new();
    fo.update_fetchhead(true);
    fo.remote_callbacks(callbacks);
    fo.prune(git2::FetchPrune::On);

    builder.fetch_options(fo);
    let path = Path::new(path_string.as_str());
    let repo = builder.clone(url.as_str(), path)?;

    set_author(&repo, &author);
    repo.cleanup_state();

    _log(
        Arc::clone(&log_callback),
        LogType::CloneRepo,
        "Repository cloned successfully".to_string(),
    );
    
    repo.submodules()?.iter_mut().try_for_each(|sm| {
        let sm_name = sm.name().unwrap_or("unknown").to_string();
        
        _log(
            Arc::clone(&log_callback),
            LogType::CloneRepo,
            format!("Processing submodule: {}", sm_name),
        );
        
        let mut options = SubmoduleUpdateOptions::new();
        let mut fetch_opts = FetchOptions::new();
        fetch_opts.remote_callbacks(get_default_callbacks(Some(&provider), Some(&credentials)));
        fetch_opts.prune(git2::FetchPrune::On);
        options.fetch(fetch_opts);
        options.allow_fetch(true);
        
        sm.init(true)?;
        sm.update(true, Some(&mut options))?;
        
        let sm_repo_result = sm.open();
        if let Ok(sm_repo) = sm_repo_result {
            if let Ok(head) = sm_repo.head() {
                if let Some(target_commit_id) = head.target() {
                    _log(
                        Arc::clone(&log_callback),
                        LogType::CloneRepo,
                        format!("Submodule {} is at commit: {}", sm_name, target_commit_id),
                    );
                    
                    let mut found_branch = false;
                    
                    // Try to find a local branch that contains this commit
                    if let Ok(branches) = sm_repo.branches(Some(BranchType::Local)) {
                        for branch_result in branches {
                            if let Ok((branch, _)) = branch_result {
                                let branch_name_opt = branch.name().ok().flatten().map(|s| s.to_string());
                                if let Some(branch_name) = branch_name_opt {
                                    let branch_ref = branch.into_reference();
                                    
                                    if let Ok(branch_commit) = branch_ref.peel_to_commit() {
                                        if branch_commit.id() == target_commit_id {
                                            // Checkout the branch
                                            let branch_ref_name = format!("refs/heads/{}", branch_name);
                                            if let Ok(branch_ref) = sm_repo.find_reference(&branch_ref_name) {
                                                if let Ok(tree) = branch_ref.peel_to_tree() {
                                                    let _ = sm_repo.checkout_tree(
                                                        tree.as_object(),
                                                        Some(git2::build::CheckoutBuilder::new().force())
                                                    );
                                                    let _ = sm_repo.set_head(&branch_ref_name);
                                                    
                                                    _log(
                                                        Arc::clone(&log_callback),
                                                        LogType::CloneRepo,
                                                        format!("Successfully checked out branch '{}' in submodule {}", branch_name, sm_name),
                                                    );
                                                    found_branch = true;
                                                    break;
                                                }
                                            }
                                        } else {
                                            // Check if target commit is reachable from this branch
                                            if let Ok(mut revwalk) = sm_repo.revwalk() {
                                                revwalk.push(branch_commit.id()).ok();
                                                revwalk.set_sorting(git2::Sort::TIME).ok();
                                                
                                                for commit_id in revwalk.take(100) { 
                                                    if let Ok(commit_id) = commit_id {
                                                        if commit_id == target_commit_id {
                                                            let branch_ref_name = format!("refs/heads/{}", branch_name);
                                                            if let Ok(branch_ref) = sm_repo.find_reference(&branch_ref_name) {
                                                                if let Ok(tree) = branch_ref.peel_to_tree() {
                                                                    let _ = sm_repo.checkout_tree(
                                                                        tree.as_object(),
                                                                        Some(git2::build::CheckoutBuilder::new().force())
                                                                    );
                                                                    let _ = sm_repo.set_head(&branch_ref_name);
                                                                    
                                                                    _log(
                                                                        Arc::clone(&log_callback),
                                                                        LogType::CloneRepo,
                                                                        format!("Found branch '{}' containing commit, checked out in submodule {}", branch_name, sm_name),
                                                                    );
                                                                    found_branch = true;
                                                                    break;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                if found_branch { break; }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if !found_branch {
                        if let Ok(branches) = sm_repo.branches(Some(BranchType::Remote)) {
                            for branch_result in branches {
                                if let Ok((branch, _)) = branch_result {
                                    let branch_name_opt = branch.name().ok().flatten().map(|s| s.to_string());
                                    if let Some(remote_branch_name) = branch_name_opt {
                                        let branch_ref = branch.into_reference();
                                        
                                        // Check if this remote branch contains our target commit
                                        if let Ok(branch_commit) = branch_ref.peel_to_commit() {
                                            if branch_commit.id() == target_commit_id {
                                                let local_branch_name = if let Some(slash_pos) = remote_branch_name.find('/') {
                                                    &remote_branch_name[slash_pos + 1..]
                                                } else {
                                                    &remote_branch_name
                                                };
                                                
                                                if let Ok(target_commit) = sm_repo.find_commit(target_commit_id) {
                                                    if let Ok(_local_branch) = sm_repo.branch(local_branch_name, &target_commit, false) {
                                                        if let Ok(mut config) = sm_repo.config() {
                                                            let _ = config.set_str(
                                                                &format!("branch.{}.remote", local_branch_name),
                                                                "origin"
                                                            );
                                                            let _ = config.set_str(
                                                                &format!("branch.{}.merge", local_branch_name),
                                                                &format!("refs/heads/{}", local_branch_name)
                                                            );
                                                        }
                                                        
                                                        // Checkout the new local branch
                                                        let branch_ref_name = format!("refs/heads/{}", local_branch_name);
                                                        if let Ok(tree) = target_commit.tree() {
                                                            let _ = sm_repo.checkout_tree(
                                                                tree.as_object(),
                                                                Some(git2::build::CheckoutBuilder::new().force())
                                                            );
                                                            let _ = sm_repo.set_head(&branch_ref_name);
                                                            
                                                            _log(
                                                                Arc::clone(&log_callback),
                                                                LogType::CloneRepo,
                                                                format!("Created and checked out local branch '{}' from '{}' in submodule {}", local_branch_name, remote_branch_name, sm_name),
                                                            );
                                                            found_branch = true;
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if !found_branch {
                        _log(
                            Arc::clone(&log_callback),
                            LogType::CloneRepo,
                            format!("No branch found containing commit in submodule {}, staying in detached HEAD", sm_name),
                        );
                    }
                }
            }
        }
        
        Ok::<(), git2::Error>(())
    })?;
    
    set_author(&repo, &author);
    repo.cleanup_state();
    
    _log(
        Arc::clone(&log_callback),
        LogType::CloneRepo,
        "Submodules updated successfully".to_string(),
    );
    
    Ok(())
}

pub async fn unstage_all(
    path_string: &String,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::Stage,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(path_string)?;
    let mut index = repo.index()?;

    let paths: Vec<PathBuf> = index
        .iter()
        .map(|entry| {
            let s = String::from_utf8_lossy(entry.path.as_slice()).into_owned();
            PathBuf::from(s)
        })
        .collect();

    for path in paths {
        index.remove_path(&path)?;
    }

    index.write()?;

    _log(
        Arc::clone(&log_callback),
        LogType::Stage,
        "Unstaged all!".to_string(),
    );
    
    Ok(())
}

pub async fn get_diff(
    path_string: &String,
    start_ref: &String,
    end_ref:&String,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<Diff, git2::Error> {
    init(None);
    let log_callback = Arc::new(log);

    let insertion_marker: &str = "+++++insertion+++++";
    let deletion_marker: &str = "-----deletion-----";

    _log(
        Arc::clone(&log_callback),
        LogType::Diff,
        "Getting local directory".to_string(),
    );

    let repo = Repository::open(path_string)?;

    let tree1 = repo.revparse_single(start_ref)?.peel_to_commit()?.tree()?;
    let tree2 = repo.revparse_single(end_ref)?.peel_to_commit()?.tree()?;
    
    let mut diff_opts = DiffOptions::new();
    
    let diff = repo.diff_tree_to_tree(
        Some(&tree2),
        Some(&tree1),
        Some(&mut diff_opts)
    )?;

    _log(
        Arc::clone(&log_callback),
        LogType::Diff,
        "Getting diff stats".to_string(),
    );

    let diff_stats = diff.stats()?;

    _log(
        Arc::clone(&log_callback),
        LogType::Diff,
        "Getting diff hunks".to_string(),
    );

    let mut diff_parts: HashMap<String, HashMap<String, String>> = HashMap::new();

    diff.foreach(
        &mut |delta: git2::DiffDelta, _progress: f32| -> bool {
            true
        },
        None,
        Some(&mut |delta: git2::DiffDelta, hunk: git2::DiffHunk| -> bool {
            true
        }),
        Some(&mut |delta: git2::DiffDelta, hunk: Option<git2::DiffHunk>, line: git2::DiffLine| -> bool {
            let old_file_path = delta.old_file().path()
                .map(|p| p.display().to_string())
                .unwrap_or_else(|| "Unknown".to_string());
            let new_file_path = delta.new_file().path()
            .map(|p| p.display().to_string())
            .unwrap_or_else(|| "Unknown".to_string());

            let mut hunk_header = "none".to_string();

            if let Some(hunk) = hunk {
                if !hunk.header().is_empty() {
                    hunk_header = String::from_utf8_lossy(hunk.header()).to_string();
                }
            }

            let file_path_key = if old_file_path == new_file_path { new_file_path } else { format!("{}=>{}", old_file_path, new_file_path) };

            let line_text = String::from_utf8_lossy(line.content()).to_string();

            match line.origin() {
                '+' => {
                    diff_parts
                        .entry(file_path_key.clone())
                        .or_default()
                        .entry(hunk_header.clone())
                        .and_modify(|existing_content| {
                            *existing_content = format!(
                                "{}{}", 
                                existing_content, 
                                format!("{}{}", &insertion_marker, line_text).to_string()
                            );
                        })
                        .or_insert_with(|| format!("{}{}", &insertion_marker, line_text).to_string());
                },
                '-' => {
                    diff_parts
                        .entry(file_path_key.clone())
                        .or_default()
                        .entry(hunk_header.clone())
                        .and_modify(|existing_content| {
                            *existing_content = format!(
                                "{}{}", 
                                existing_content, 
                                format!("{}{}", &deletion_marker, line_text).to_string()
                            );
                        })
                        .or_insert_with(|| format!("{}{}", &deletion_marker, line_text).to_string());
                },
                '>' => {},
                '<' => {},
                '=' => {},
                'F' => {},
                'H' => {},
                'B' => {},
                ' ' => {
                    diff_parts
                        .entry(file_path_key.clone())
                        .or_default()
                        .entry(hunk_header.clone())
                        .and_modify(|existing_content| {
                            *existing_content = format!(
                                "{}{}", 
                                existing_content, 
                                format!("{}", line_text).to_string()
                            );
                        })
                        .or_insert_with(|| format!("{}", line_text).to_string());
                },
                _ => {
                    _log(
                        Arc::clone(&log_callback),
                        LogType::Diff,
                        format!("Other: {}", line.origin())
                    );
                } 
            }

            true
        })
    );

    Ok(Diff {
        files_changed: diff_stats.files_changed() as i32,
        insertions: diff_stats.insertions() as i32,
        deletions: diff_stats.deletions() as i32,
        diff_parts: diff_parts
    })
}

pub async fn get_recent_commits(
    path_string: &String,
    remote_name: &str,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<Vec<Commit>, git2::Error> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::RecentCommits,
        "Getting local directory".to_string(),
    );

    let repo = Repository::open(path_string)?;
    let branch_name = get_branch_name_priv(&repo);
    let mut local_oid: Option<git2::Oid> = None;
    let mut remote_oid: Option<git2::Oid> = None;

    let mut revwalk = repo.revwalk()?;

    if let Some(name) = branch_name {
        let local_branch = repo.find_branch(&name, BranchType::Local)?;
        local_oid = Some(local_branch.get().target().ok_or_else(|| git2::Error::from_str("Invalid local branch"))?);
        let remote_ref = format!("refs/remotes/{}/{}", remote_name, name);
        remote_oid = repo.refname_to_id(&remote_ref).ok();
        if let Some(local_oid) = local_oid {
            revwalk.push(local_oid)?;
        }
        if let Some(remote_oid) = remote_oid {
            revwalk.push(remote_oid)?;
        }
    } else {
        match revwalk.push_head() {
            Ok(_) => {},
            Err(_) => return Ok(Vec::new()), 
        }
    }

    revwalk.set_sorting(git2::Sort::TOPOLOGICAL | git2::Sort::TIME)?;

    let mut commits: Vec<Commit> = Vec::new();

    for oid_result in revwalk.take(50) {
        let oid = match oid_result {
            Ok(id) => id,
            Err(_) => continue,
        };

        let commit = match repo.find_commit(oid) {
            Ok(c) => c,
            Err(_) => continue,
        };

        let author = commit.author().name().unwrap_or("<unknown>").to_string();
        let time = commit.time().seconds();
        let message = commit.message().unwrap_or("<no message>").trim().to_string();
        let reference = format!("{}", oid);

        let parent = commit.parent(0).ok();
        let mut diff_opts = DiffOptions::new();
        let diff = match parent {
            Some(parent_commit) => repo.diff_tree_to_tree(
                Some(&parent_commit.tree()?),
                Some(&commit.tree()?),
                Some(&mut diff_opts),
            )?,
            None => repo.diff_tree_to_tree(None, Some(&commit.tree()?), Some(&mut diff_opts))?,
        };

        let (additions, deletions) = match diff.stats() {
            Ok(s) => (s.insertions() as i32, s.deletions() as i32),
            Err(_) => (0, 0),
        };

        let (ahead_local, _) = if let Some(local_oid) = local_oid {
            repo.graph_ahead_behind(oid, local_oid)?
        } else {
            (0, 0)
        };
        let (ahead_remote, _) = if let Some(remote_oid) = remote_oid {
            repo.graph_ahead_behind(oid, remote_oid)?
        } else {
            (0, 0)
        };
        let unpulled = ahead_local > 0;
        let unpushed = ahead_remote > 0;

        commits.push(Commit {
            timestamp: time,
            author,
            reference,
            commit_message: message,
            additions,
            deletions,
            unpushed,
            unpulled,
        });
    }

    _log(
        Arc::clone(&log_callback),
        LogType::RecentCommits,
        format!("Retrieved {} recent commits", commits.len()),
    );

    Ok(commits)
}

fn fast_forward(
    repo: &Repository,
    lb: &mut git2::Reference,
    rc: &git2::AnnotatedCommit,
    log_callback: &Arc<impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static>,
) -> Result<(), git2::Error> {
    _log(
        Arc::clone(&log_callback),
        LogType::PullFromRepo,
        "Fast forward".to_string(),
    );
    let name = match lb.name() {
        Some(s) => s.to_string(),
        None => String::from_utf8_lossy(lb.name_bytes()).to_string(),
    };
    let msg = format!("Fast-Forward: Setting {} to id: {}", name, rc.id());

    _log(
        Arc::clone(&log_callback),
        LogType::PullFromRepo,
        msg.to_string(),
    );
    lb.set_target(rc.id(), &msg)?;
    repo.set_head(&name)?;
    repo.checkout_head(Some(
        git2::build::CheckoutBuilder::default()
            .allow_conflicts(true)
            .conflict_style_merge(true)
            .safe()
            .force(), // // For some reason the force is required to make the working directory actually get updated
                      // // I suspect we should be adding some logic to handle dirty working directory states
                      // // but this is just an example so maybe not.
                      // .force(),
    ))?;
    Ok(())
}

fn commit(
    repo: &Repository,
    update_ref: Option<&str>,
    author_committer: &Signature<'_>,
    message: &str,
    tree: &Tree<'_>,
    parents: &[&git2::Commit<'_>],
    commit_signing_credentials: Option<(String, String)>,
    log_callback: &Arc<impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static>,
) -> Result<git2::Oid, git2::Error> {
	let commit_id = if let Some((ref pass, ref key)) = commit_signing_credentials
	{
        _log(
            Arc::clone(&log_callback),
            LogType::Commit,
            "Signing commit".to_string(),
        );
		let buffer = repo.commit_create_buffer(
			&author_committer,
			&author_committer,
			message,
			&tree,
			parents,
		)?;

		let commit = std::str::from_utf8(&buffer).map_err(|_e| {
			git2::Error::from_str(&"utf8 conversion error".to_string())
		})?;

        
        let secret_key = PrivateKey::from_openssh(key.as_bytes())
            .map_err(|e| git2::Error::from_str(&e.to_string()))?;
        if !pass.is_empty() {
            secret_key.decrypt(pass.as_bytes())
                .map_err(|e| git2::Error::from_str(&e.to_string()))?;
        }
        _log(
            Arc::clone(&log_callback),
            LogType::Commit,
            "Committing".to_string(),
        );
        let sig = secret_key
            .sign("git", HashAlg::Sha256, &commit.as_bytes())
            .map_err(|e| git2::Error::from_str(&e.to_string()))?
            .to_pem(LineEnding::LF)
            .map_err(|e| git2::Error::from_str(&e.to_string()))?;

            let commit_id = repo.commit_signed(
			commit,
			&sig,
			None,
		)?;

		if let Ok(mut head) = repo.head() {
			head.set_target(commit_id, message)?;
		} else {
            let current_branch = get_branch_name_priv(&repo).unwrap_or_else(|| "master".to_string());
            
			repo.reference(
				&format!("refs/heads/{current_branch}"),
				commit_id,
				true,
				message,
			)?;
		}

		commit_id
	} else {
        _log(
            Arc::clone(&log_callback),
            LogType::Commit,
            "Committing".to_string(),
        );
		repo.commit(
			update_ref,
			&author_committer,
			&author_committer,
			message,
			&tree,
			parents,
		)?
	};

	Ok(commit_id.into())
}

pub async fn update_submodules(
    path_string: &str, 
    provider: &String,
    credentials: &(String, String),
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(&path_string)?;

    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    
    update_submodules_priv(&repo, &provider, &credentials, &log_callback)
}

fn update_submodules_priv(
    repo: &Repository,
    provider: &String,
    credentials: &(String, String),
    log_callback: &Arc<impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static>,
) -> Result<(), git2::Error> {
    for mut submodule in repo.submodules()? {
        let name = submodule.name().unwrap_or("unknown").to_string();

        _log(
            Arc::clone(&log_callback),
            LogType::PullFromRepo,
            format!("Updating submodule: {}", name),
        );

        let callbacks = get_default_callbacks(Some(&provider), Some(&credentials));
        let mut fetch_options = FetchOptions::new();
        fetch_options.prune(git2::FetchPrune::On);
        fetch_options.update_fetchhead(true);
        fetch_options.remote_callbacks(callbacks);
        fetch_options.download_tags(git2::AutotagOption::All);


        let mut submodule_opts = git2::SubmoduleUpdateOptions::new();
        submodule_opts.fetch(fetch_options);

        submodule.update(true, Some(&mut submodule_opts))?;

        if let Ok(sub_repo) = submodule.open() {
            sub_repo.checkout_head(Some(
                git2::build::CheckoutBuilder::default()
                    .allow_conflicts(true)
                    .conflict_style_merge(true)
                    .force(),
            ))?;
        }
    }
    Ok(())
}

pub async fn fetch_remote(
    path_string: &str, 
    remote: &String,
    provider: &String,
    credentials: &(String, String),
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<Option<bool>, git2::Error> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(&path_string)?;

    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    
    fetch_remote_priv(&repo, &remote, &provider, &credentials, &log_callback)
}

fn fetch_remote_priv(
    repo: &Repository,
    remote: &String,
    provider: &String,
    credentials: &(String, String),
    log_callback: &Arc<impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static>,
) -> Result<Option<bool>, git2::Error> {
    let mut remote = repo.find_remote(&remote)?;

    let callbacks = get_default_callbacks(Some(&provider), Some(&credentials));
    let mut fetch_options = FetchOptions::new();
    fetch_options.prune(git2::FetchPrune::On);
    fetch_options.update_fetchhead(true);
    fetch_options.remote_callbacks(callbacks);
    fetch_options.download_tags(git2::AutotagOption::All);

    _log(
        Arc::clone(&log_callback),
        LogType::PullFromRepo,
        "Fetching changes".to_string(),
    );
    remote.fetch::<&str>(&[], Some(&mut fetch_options), None)?;
    return Ok(Some(true));
}

pub async fn pull_changes(
    path_string: &String,
    provider: &String,
    credentials: &(String, String),
    commit_signing_credentials: Option<(String, String)>,
    sync_callback: impl Fn() -> DartFnFuture<()> + Send + Sync + 'static,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<Option<bool>, git2::Error> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(&path_string)?;

    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    
    pull_changes_priv(&repo, &provider, &credentials, commit_signing_credentials, sync_callback, &log_callback)
}

fn pull_changes_priv(
    repo: &Repository,
    provider: &String,
    credentials: &(String, String),
    commit_signing_credentials: Option<(String, String)>,
    sync_callback: impl Fn() -> DartFnFuture<()> + Send + Sync + 'static,
    log_callback: &Arc<impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static>,
) -> Result<Option<bool>, git2::Error> {
    let result = match repo.head() {
        Ok(h) => Some(h),
        Err(e) => {
            if e.code() == git2::ErrorCode::UnbornBranch {
                None
            } else {
                return Err(e);
            }
        }
    };
    
    if result.is_none() {
        return Ok(Some(false));
    }
    
    let head = result.unwrap();
    let resolved_head = head.resolve()?;
    let remote_branch = resolved_head.shorthand()
        .ok_or_else(|| git2::Error::from_str("Could not determine branch name"))?;

    let fetch_head = repo.find_reference("FETCH_HEAD")?;
    let fetch_commit = repo.reference_to_annotated_commit(&fetch_head)?;
    let analysis = repo.merge_analysis(&[&fetch_commit])?;

    if analysis.0.is_up_to_date() {
        _log(
            Arc::clone(&log_callback),
            LogType::PullFromRepo,
            "Already up to date".to_string(),
        );
        return Ok(Some(false));
    }

    flutter_rust_bridge::spawn(async move {
        sync_callback().await;
    });

    if analysis.0.is_fast_forward() {
        _log(
            Arc::clone(&log_callback),
            LogType::PullFromRepo,
            "Doing a fast forward".to_string(),
        );
        let refname = format!("refs/heads/{}", remote_branch);
        match repo.find_reference(&refname) {
            Ok(mut r) => {
                _log(
                    Arc::clone(&log_callback),
                    LogType::PullFromRepo,
                    "OK fast forward".to_string(),
                );
                if get_staged_file_paths_priv(&repo, &log_callback).is_empty() && get_uncommitted_file_paths_priv(&repo, false, &log_callback).is_empty() {
                    fast_forward(&repo, &mut r, &fetch_commit, &log_callback)?;
                    update_submodules_priv(&repo, &provider, &credentials, &log_callback)?;
                } else {
                    _log(
                        Arc::clone(&log_callback),
                        LogType::PullFromRepo,
                        "Uncommitted changes exist!".to_string(),
                    );
                    return Ok(Some(false));
                }
                return Ok(Some(true));
            }
            Err(_) => {
                _log(
                    Arc::clone(&log_callback),
                    LogType::PullFromRepo,
                    "Err fast forward".to_string(),
                );
                repo.reference(
                    &refname,
                    fetch_commit.id(),
                    true,
                    &format!("Setting {} to {}", remote_branch, fetch_commit.id()),
                )?;
                repo.set_head(&refname)?;
                repo.checkout_head(Some(
                    git2::build::CheckoutBuilder::default()
                        .allow_conflicts(true)
                        .conflict_style_merge(true)
                        .force(),
                ))?;
                update_submodules_priv(&repo, &provider, &credentials, &log_callback)?;
                return Ok(Some(true));
            }
        };
    } else if analysis.0.is_normal() {
        _log(
            Arc::clone(&log_callback),
            LogType::PullFromRepo,
            "Pulling changes".to_string(),
        );
        let head_commit = repo.reference_to_annotated_commit(&repo.head()?)?;
        _log(
            Arc::clone(&log_callback),
            LogType::PullFromRepo,
            "Normal merge".to_string(),
        );
        let local_tree = repo.find_commit(head_commit.id())?.tree()?;
        let remote_tree = repo.find_commit(fetch_commit.id())?.tree()?;
        let ancestor = repo
            .find_commit(repo.merge_base(head_commit.id(), fetch_commit.id())?)?
            .tree()?;
        let mut idx = repo.merge_trees(&ancestor, &local_tree, &remote_tree, None)?;

        if idx.has_conflicts() {
            _log(
                Arc::clone(&log_callback),
                LogType::PullFromRepo,
                "Merge conflicts detected".to_string(),
            );

            return Ok(Some(false));
        }
        let result_tree = repo.find_tree(idx.write_tree_to(&repo)?)?;
        let msg = format!("Merge: {} into {}", fetch_commit.id(), head_commit.id());
        let sig = repo.signature()?;
        let local_commit = repo.find_commit(head_commit.id())?;
        let remote_commit = repo.find_commit(fetch_commit.id())?;
        commit(
            &repo,
            Some("HEAD"),
            &sig,
            &msg,
            &result_tree,
            &[&local_commit, &remote_commit],
            commit_signing_credentials,
            &log_callback,
        )?;
        repo.checkout_head(None)?;
        return Ok(Some(true));
    } else {
        return Ok(Some(false));
    }
}

pub async fn download_changes(
    path_string: &String,
    remote: &String,
    provider: &String,
    credentials: &(String, String),
    commit_signing_credentials: Option<(String, String)>,
    author: &(String, String),
    sync_callback: impl Fn() -> DartFnFuture<()> + Send + Sync + 'static,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<Option<bool>, git2::Error> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::PullFromRepo,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(path_string)?;
    set_author(&repo, &author);
    repo.cleanup_state();

    fetch_remote_priv(&repo, &remote, &provider, &credentials, &log_callback);

    if pull_changes_priv(&repo, &provider, &credentials, commit_signing_credentials, sync_callback, &log_callback) == Ok(Some(false)) {
        return Ok(Some(false));
    }

    Ok(Some(true))
}

pub async fn push_changes(
    path_string: &String,
    remote_name: &String,
    provider: &String,
    credentials: &(String, String),
    merge_conflict_callback: impl Fn() -> DartFnFuture<()> + Send + Sync + 'static,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<Option<bool>, git2::Error> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(&path_string)?;

    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    
    push_changes_priv(&repo, &remote_name, &provider, &credentials, merge_conflict_callback, &log_callback)
}

fn push_changes_priv(
    repo: &Repository,
    remote_name: &String,
    provider: &String,
    credentials: &(String, String),
    merge_conflict_callback: impl Fn() -> DartFnFuture<()> + Send + Sync + 'static,
    log_callback: &Arc<impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static>,
) -> Result<Option<bool>, git2::Error> {
    let mut remote = repo.find_remote(&remote_name)?;
    let callbacks = get_default_callbacks(Some(&provider), Some(&credentials));

    let mut push_options = PushOptions::new();
    push_options.remote_callbacks(callbacks);

    let result = match repo.head() {
        Ok(h) => Some(h),
        Err(e) => {
            if e.code() == git2::ErrorCode::UnbornBranch {
                None
            } else {
                return Err(e);
            }
        }
    };

    if result.is_none() {
        return Ok(Some(false));
    }

    let git_dir = repo.path();
    let rebase_head_path = git_dir.join("rebase-merge").join("head-name");

    let refname = if rebase_head_path.exists() {
        let content = fs::read_to_string(&rebase_head_path)
            .map_err(|err| git2::Error::from_str(&format!(
                "Failed to read rebase head-name file: {}", err
            )))?;
        
        content.trim().to_string()
    } else {
        let head = repo.head()?;
        let resolved_head = head.resolve()?;
        let branch_name = resolved_head.shorthand()
            .ok_or_else(|| git2::Error::from_str("Could not determine branch name"))?;
        
        format!("refs/heads/{}", branch_name)
    };

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Pushing changes".to_string(),
    );

    match remote.push(&[&refname], Some(&mut push_options)) {
        Ok(_) => _log(
            Arc::clone(&log_callback),
            LogType::PushToRepo,
            "Push successful".to_string(),
        ),
        Err(e) if e.code() == ErrorCode::NotFastForward => {
            _log(
                Arc::clone(&log_callback),
                LogType::PushToRepo,
                "Attempting rebase on REJECTED_NONFASTFORWARD".to_string(),
            );

            let head = repo.head()?;
            let branch_name = head
                .shorthand()
                .ok_or_else(|| git2::Error::from_str("Invalid branch"))?;

            let remote_branch_ref = format!("refs/remotes/{}/{}", remote_name, branch_name);

            _log(
                Arc::clone(&log_callback),
                LogType::PushToRepo,
                "Attempting rebase on REJECTED_NONFASTFORWARD2".to_string(),
            );
            
            if repo.state() == RepositoryState::Rebase
                || repo.state() == RepositoryState::RebaseMerge
            {
                let mut rebase = repo.open_rebase(None)?;
                while let Some(op) = rebase.next() {
                    let commit_id = op?.id();
                    let commit = repo.find_commit(commit_id)?;
                    rebase.commit(None, &commit.author(), None)?;
                }
                match rebase.finish(None) {
                    Ok(_) => {
                        return Ok(Some(true));
                    }
                    Err(e) if e.code() == ErrorCode::Modified || e.code() == ErrorCode::Unmerged => {
                        rebase.abort()?;
                    }
                    Err(e) => {
                        _log(
                            Arc::clone(&log_callback),
                            LogType::PushToRepo,
                            format!("{:?}", e.code()),
                        );
                        _log(
                            Arc::clone(&log_callback),
                            LogType::PushToRepo,
                            (e.code() == ErrorCode::Unmerged).to_string(),
                        );
                        return Err(e)
                    },
                }
            }

            _log(
                Arc::clone(&log_callback),
                LogType::PushToRepo,
                "Attempting rebase on REJECTED_NONFASTFORWARD3".to_string(),
            );

            if repo.state() != RepositoryState::Clean {
                if let Some(mut rebase) = repo.open_rebase(None).ok() {
                    rebase.abort()?;
                }
            }

            let remote_branch = repo.find_reference(&remote_branch_ref)?;
            let annotated_commit = repo.reference_to_annotated_commit(&remote_branch)?;
            let mut rebase =
                repo.rebase(None, Some(&annotated_commit), Some(&annotated_commit), None)?;

            while let Some(op) = rebase.next() {
                let commit_id = op?.id();
                match rebase.commit(None, &repo.find_commit(commit_id)?.author(), None) {
                    Ok(_) => {}
                    Err(e) if e.code() == ErrorCode::Unmerged => {
                        _log(
                            Arc::clone(&log_callback),
                            LogType::PushToRepo,
                            "Unmerged changes found!".to_string(),
                        );
                        flutter_rust_bridge::spawn(async move {
                            merge_conflict_callback().await;
                        });
                        return Ok(Some(false));
                    }
                    Err(e) if e.code() == ErrorCode::Applied => {
                        _log(
                            Arc::clone(&log_callback),
                            LogType::PushToRepo,
                            "Skipping already applied patch".to_string(),
                        );
                        continue;
                    }
                    Err(e) => {
                        _log(
                            Arc::clone(&log_callback),
                            LogType::PushToRepo,
                            format!("Error: {}; code={}", e.message(), e.code() as i32),
                        );
                        return Err(e);
                    }
                }
            }

            rebase.finish(None)?;

            _log(
                Arc::clone(&log_callback),
                LogType::PushToRepo,
                "Push successful".to_string(),
            );
            _log(
                Arc::clone(&log_callback),
                LogType::PushToRepo,
                "Pushing changes".to_string(),
            );

            remote.push(&[&refname], Some(&mut push_options))?;
        }
        Err(e) => return Err(e),
    }

    Ok(Some(true))
}

pub async fn stage_file_paths(
    path_string: &String,
    paths: Vec<String>,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(&path_string)?;

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Retrieved Statuses".to_string(),
    );

    let mut index = repo.index()?;

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Adding Files to Stage".to_string(),
    );

    match index.add_all(paths.iter(), git2::IndexAddOption::DEFAULT, None) {
        Ok(_) => {}
        Err(_) => { index.update_all(paths.iter(), None)?; }
    }

    for path in &paths {
        if let Ok(mut sm) = repo.find_submodule(path) {
            let sm_repo = sm.open()?;
            sm_repo.index()?.write()?;
            sm.add_to_index(false)?;
        }
    }

    index.write()?;

    if !index.has_conflicts() {
        index.write_tree()?;
    }

    Ok(())
}


pub async fn unstage_file_paths(
    path_string: &String,
    paths: Vec<String>,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(&path_string)?;

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Retrieved Statuses".to_string(),
    );

    let mut index = repo.index()?;

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Removing Files from Stage".to_string(),
    );

    let head = repo.head()?;
    let commit = head.peel_to_commit()?;
    repo.reset_default(Some(commit.as_object()), paths.iter())?;

    index.write()?;

    if !index.has_conflicts() {
        index.write_tree()?;
    }

    Ok(())
}

pub async fn get_recommended_action(
    path_string: &String,
    remote_name: &String,
    provider: &String,
    credentials: &(String, String),
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<Option<i32>, git2::Error> {
    init(None);
    let log_callback = Arc::new(log);
    let repo = git2::Repository::open(path_string)?;
    let callbacks = get_default_callbacks(Some(&provider), Some(&credentials));
    let branch_name = get_branch_name_priv(&repo).unwrap_or_else(|| "master".to_string());

    if let Ok(mut remote) = repo.find_remote(remote_name) {
        remote.connect_auth(git2::Direction::Fetch, Some(callbacks), None)?;
        let remote_refs = remote.list()?;
        let tracking_ref_name = format!("refs/remotes/{}/{}", remote.name().unwrap(), &branch_name);
        let mut found = false;
                
        if let Ok(tracking_ref) = repo.find_reference(&tracking_ref_name) {
            for r in remote_refs {
                if tracking_ref.target() == Some(r.oid()) { 
                    found = true;
                }            
            }
        } else {
            _log(
                Arc::clone(&log_callback),
                LogType::GitStatus,
                format!("Recommending action 0: No local tracking reference found. Expected ref: {}", tracking_ref_name)
            );
            return Ok(Some(0));
        }

        if (!found) {
            _log(
                Arc::clone(&log_callback),
                LogType::GitStatus,
                format!("Recommending action 0: Remote reference differs from local tracking reference. Ref: {}", tracking_ref_name)
            );
            return Ok(Some(0));
        }
        remote.disconnect();
    }

    if !get_staged_file_paths_priv(&repo, &log_callback).is_empty() || !get_uncommitted_file_paths_priv(&repo, false, &log_callback).is_empty() {
        _log(
            Arc::clone(&log_callback),
            LogType::GitStatus,
            "Recommending action 2: Staged or uncommitted files exist".to_string()
        );
        return Ok(Some(2));
    }

    if let Ok(head) = repo.head() {
        if let Ok(local_commit) = head.peel_to_commit() {
            if let Ok(remote_branch) = repo.find_branch(&format!("{}/{}", remote_name, head.shorthand().unwrap_or("")), git2::BranchType::Remote) {
                if let Ok(remote_commit) = remote_branch.get().peel_to_commit() {
                    if local_commit.id() != remote_commit.id() {
                        let (ahead, behind) = repo.graph_ahead_behind(local_commit.id(), remote_commit.id())?;
                        if ahead > 0 {
                            _log(
                                Arc::clone(&log_callback),
                                LogType::GitStatus,
                                format!("Recommending action 3: Local branch is ahead of remote by {} commits", ahead)
                            );
                            return Ok(Some(3));
                        } else if behind > 0 {
                            _log(
                                Arc::clone(&log_callback),
                                LogType::GitStatus,
                                format!("Recommending action 1: Local branch is behind remote by {} commits", behind)
                            );
                            return Ok(Some(1));
                        }
                        _log(
                            Arc::clone(&log_callback),
                            LogType::GitStatus,
                            "Recommending action 3: Unhandled commit difference".to_string()
                        );
                        return Ok(Some(3));
                    }
                }
            }
        }
    }
    
    Ok(None)
}

pub async fn commit_changes(
    path_string: &String,
    commit_signing_credentials: Option<(String, String)>,
    author: &(String, String),
    sync_message: &String,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(&path_string)?;
    set_author(&repo, &author);


    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Retrieved Statuses".to_string(),
    );

    let mut index = repo.index()?;
    let updated_tree_oid = if !index.has_conflicts() {
        Some(index.write_tree()?)
    } else {
        None
    };

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Committing changes".to_string(),
    );
    
    let signature = repo
        .signature()
        .or_else(|_| Signature::now(&author.0, &author.1))?;

    let parents = match repo.head()
        .ok()
        .and_then(|h| h.resolve().ok())
        .and_then(|h| h.peel_to_commit().ok()) {
            Some(commit) => vec![commit],
            None => vec![],
        };


    let tree_oid = updated_tree_oid.unwrap_or_else(|| index.write_tree_to(&repo).unwrap());
    let tree = repo.find_tree(tree_oid)?;

    commit(
        &repo,
        Some("HEAD"),
        &signature,
        &sync_message,
        &tree,
        &parents.iter().collect::<Vec<_>>(),
        commit_signing_credentials,
        &log_callback,
    )?;

    Ok(())
}

pub async fn upload_changes(
    path_string: &String,
    remote_name: &String,
    provider: &String,
    credentials: &(String, String),
    commit_signing_credentials: Option<(String, String)>,
    author: &(String, String),
    file_paths: Option<Vec<String>>,
    sync_message: &String,
    sync_callback: impl Fn() -> DartFnFuture<()> + Send + Sync + 'static,
    merge_conflict_callback: impl Fn() -> DartFnFuture<()> + Send + Sync + 'static,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<Option<bool>, git2::Error> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(&path_string)?;
    set_author(&repo, &author);


    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Retrieved Statuses".to_string(),
    );

    let uncommitted_file_paths: Vec<(String, i32)> = get_staged_file_paths_priv(&repo, &log_callback).into_iter().chain(get_uncommitted_file_paths_priv(&repo, true, &log_callback)).collect();

    let mut index = repo.index()?;

    // Store the initial index state to compare later
    let has_conflicts = index.has_conflicts();
    let initial_tree_oid = if !has_conflicts {
        Some(index.write_tree()?)
    } else {
        None
    };
    
    if !uncommitted_file_paths.is_empty() {
        flutter_rust_bridge::spawn(async move {
            sync_callback().await;
        });
    }

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Adding Files to Stage".to_string(),
    );

    let paths: Vec<String> = if let Some(paths) = file_paths { paths } else {
        uncommitted_file_paths.into_iter().map(|(p, _)| p).collect()
    };

    match index.add_all(paths.iter(), git2::IndexAddOption::DEFAULT, None) {
        Ok(_) => {}
        Err(_) => { 
            let non_submodule_paths: Vec<&String> = paths.iter()
                .filter(|path| {
                    repo.find_submodule(path).is_err()
                })
                .collect();
            index.update_all(non_submodule_paths.iter(), None)?; 
        }
    }

    for path in &paths {
        if let Ok(mut sm) = repo.find_submodule(path) {
            let sm_repo = sm.open()?;
            sm_repo.index()?.write()?;
            sm.add_to_index(false)?;
        }
    }

    index.write()?;

    let updated_tree_oid = if !index.has_conflicts() {
        Some(index.write_tree()?)
    } else {
        None
    };


    let should_commit = match (initial_tree_oid, updated_tree_oid) {
        (Some(old), Some(new)) => old != new,
        (None, None) => true,
        _ => true,
    };
    
    // Only commit if the index has actually changed
    if should_commit {
        _log(
            Arc::clone(&log_callback),
            LogType::PushToRepo,
            "Index has changed, committing changes".to_string(),
        );
        
        let signature = repo
            .signature()
            .or_else(|_| Signature::now(&author.0, &author.1))?;

        let parents = match repo.head()
            .ok()
            .and_then(|h| h.resolve().ok())
            .and_then(|h| h.peel_to_commit().ok()) {
                Some(commit) => vec![commit],
                None => vec![],
            };


        let tree_oid = updated_tree_oid.unwrap_or_else(|| index.write_tree_to(&repo).unwrap());
        let tree = repo.find_tree(tree_oid)?;

        commit(
            &repo,
            Some("HEAD"),
            &signature,
            &sync_message,
            &tree,
            &parents.iter().collect::<Vec<_>>(),
            commit_signing_credentials,
            &log_callback,
        )?;
    } else {
        _log(
            Arc::clone(&log_callback),
            LogType::PushToRepo,
            "No changes to index, skipping commit".to_string(),
        );
    }


    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Added Files to Stage (optional)".to_string(),
    );

    push_changes_priv(&repo, &remote_name, &provider, &credentials, merge_conflict_callback, &log_callback)
}

pub async fn force_pull(
    path_string: String,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::ForcePull,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(&path_string)?;
    repo.cleanup_state();

    let fetch_commit = repo
        .find_reference("FETCH_HEAD")
        .and_then(|r| repo.reference_to_annotated_commit(&r))?;


    let git_dir = repo.path();
    let rebase_head_path = git_dir.join("rebase-merge").join("head-name");
    let refname = if rebase_head_path.exists() {
        let content = fs::read_to_string(&rebase_head_path)
            .map_err(|err| git2::Error::from_str(&format!(
                "Failed to read rebase head-name file: {}", err
            )))?;
        
        content.trim().to_string()
    } else {
        let head = repo.head()?;
        let resolved_head = head.resolve()?;
        let mut branch_name = resolved_head.shorthand()
            .ok_or_else(|| git2::Error::from_str("Could not determine branch name"))?
            .to_string();

        let orig_head_path = git_dir.join("ORIG_HEAD");
        if branch_name == "HEAD" && orig_head_path.exists() {
            let content = fs::read_to_string(&orig_head_path)
                .map_err(|err| git2::Error::from_str(&format!(
                    "Failed to read orig_head file: {}", err
                )))?;
            let orig_commit_id = content.trim();
            let orig_commit = repo.find_commit(git2::Oid::from_str(orig_commit_id)?)?;
            let branches = repo.branches(None)?;

            for branch in branches {
                let (branch_ref, _) = branch?;
                let branch_commit = repo.reference_to_annotated_commit(&branch_ref.get())?;
                
                if orig_commit.id() == branch_commit.id() {
                    branch_name = match branch_ref.name() {
                        Ok(Some(name)) => name.to_string(),
                        Ok(None) | Err(_) => return Err(git2::Error::from_str("Unable to determine branch name"))
                    };
                    break;
                }
            }
        }
        
        format!("refs/heads/{}", branch_name)
    };

    let mut reference = repo.find_reference(&refname)?;
    reference.set_target(fetch_commit.id(), "force pull")?;
    repo.set_head(&refname)?;
    repo.checkout_head(Some(
        git2::build::CheckoutBuilder::new()
            .force()
            .allow_conflicts(true)
            .conflict_style_merge(true),
    ))?;

    _log(
        Arc::clone(&log_callback),
        LogType::ForcePull,
        "Force pull successful".to_string(),
    );

    Ok(())
}

pub async fn force_push(
    path_string: String,
    remote_name: String,
    provider: String,
    credentials: (String, String),
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::ForcePush,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(&path_string)?;

    let mut remote = repo.find_remote(&remote_name)?;
    let callbacks = get_default_callbacks(Some(&provider), Some(&credentials));

    let mut push_options = PushOptions::new();
    push_options.remote_callbacks(callbacks);

    let git_dir = repo.path();
    let rebase_head_path = git_dir.join("rebase-merge").join("head-name");
    let refname = if rebase_head_path.exists() {
        let content = fs::read_to_string(&rebase_head_path)
            .map_err(|err| git2::Error::from_str(&format!(
                "Failed to read rebase head-name file: {}", err
            )))?;

        let rebase_merge = git_dir.join("rebase-merge");
        let rebase_apply = git_dir.join("rebase-apply");

        if rebase_merge.exists() {
            fs::remove_dir_all(rebase_merge).unwrap();
        }

        if rebase_apply.exists() {
            fs::remove_dir_all(rebase_apply).unwrap();
        }
        
        format!("+{}", content.trim().to_string())
    } else {
        let head = repo.head()?;
        let resolved_head = head.resolve()?;
        let mut branch_name = resolved_head.shorthand()
            .ok_or_else(|| git2::Error::from_str("Could not determine branch name"))?
            .to_string();

        let orig_head_path = git_dir.join("ORIG_HEAD");
        if branch_name == "HEAD" && orig_head_path.exists() {
            let content = fs::read_to_string(&orig_head_path)
                .map_err(|err| git2::Error::from_str(&format!(
                    "Failed to read orig_head file: {}", err
                )))?;
            let orig_commit_id = content.trim();
            let orig_commit = repo.find_commit(git2::Oid::from_str(orig_commit_id)?)?;
            let branches = repo.branches(None)?;

            for branch in branches {
                let (branch_ref, _) = branch?;
                let branch_commit = repo.reference_to_annotated_commit(&branch_ref.get())?;
                
                if orig_commit.id() == branch_commit.id() {
                    branch_name = match branch_ref.name() {
                        Ok(Some(name)) => name.to_string(),
                        Ok(None) | Err(_) => return Err(git2::Error::from_str("Unable to determine branch name"))
                    };
                    break;
                }
            }
        }
        
        format!("+refs/heads/{}", branch_name)
    };

    _log(
        Arc::clone(&log_callback),
        LogType::ForcePush,
        "Force pushing changes".to_string(),
    );

    remote.push(&[&refname], Some(&mut push_options)).unwrap();

    _log(
        Arc::clone(&log_callback),
        LogType::ForcePush,
        "Force push successful".to_string(),
    );

    Ok(())
}

pub async fn upload_and_overwrite(
    path_string: String,
    remote_name: String,
    provider: String,
    credentials: (String, String),
    commit_signing_credentials: Option<(String, String)>,
    author: (String, String),
    sync_message: String,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::ForcePush,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(&path_string)?;
    set_author(&repo, &author);

    if repo.state() == RepositoryState::Merge
        || repo.state() == RepositoryState::Rebase
        || repo.state() == RepositoryState::RebaseMerge
    {
        let mut rebase = repo.open_rebase(None)?;
        rebase.abort()?;
    }

    if !get_staged_file_paths_priv(&repo, &log_callback).is_empty() || !get_uncommitted_file_paths_priv(&repo, true, &log_callback).is_empty() {
        let mut index = repo.index()?;

        _log(
            Arc::clone(&log_callback),
            LogType::ForcePush,
            "Adding Files to Stage".to_string(),
        );

        index.add_all(["*"].iter(), git2::IndexAddOption::DEFAULT, None)?;
        index.write()?;

        let signature = repo
            .signature()
            .or_else(|_| Signature::now(&author.0, &author.1))?;

        let parent_commit = repo.head()?.resolve()?.peel_to_commit()?;
        let tree_oid = index.write_tree()?;
        let tree = repo.find_tree(tree_oid)?;

        _log(
            Arc::clone(&log_callback),
            LogType::ForcePush,
            "Committing changes".to_string(),
        );
        commit(
            &repo,
            Some("HEAD"),
            &signature,
            &sync_message,
            &tree,
            &[&parent_commit],
            commit_signing_credentials,
            &log_callback,
        )?;
    }

    let mut remote = repo.find_remote(&remote_name)?;
    let callbacks = get_default_callbacks(Some(&provider), Some(&credentials));

    let mut push_options = PushOptions::new();
    push_options.remote_callbacks(callbacks);

    let git_dir = repo.path();
    let rebase_head_path = git_dir.join("rebase-merge").join("head-name");
    let refname = if rebase_head_path.exists() {
        let content = fs::read_to_string(&rebase_head_path)
            .map_err(|err| git2::Error::from_str(&format!(
                "Failed to read rebase head-name file: {}", err
            )))?;

        let rebase_merge = git_dir.join("rebase-merge");
        let rebase_apply = git_dir.join("rebase-apply");

        if rebase_merge.exists() {
            fs::remove_dir_all(rebase_merge).unwrap();
        }

        if rebase_apply.exists() {
            fs::remove_dir_all(rebase_apply).unwrap();
        }
        
        format!("+{}", content.trim().to_string())
    } else {
        let head = repo.head()?;
        let resolved_head = head.resolve()?;
        let mut branch_name = resolved_head.shorthand()
            .ok_or_else(|| git2::Error::from_str("Could not determine branch name"))?
            .to_string();

        let orig_head_path = git_dir.join("ORIG_HEAD");
        if branch_name == "HEAD" && orig_head_path.exists() {
            let content = fs::read_to_string(&orig_head_path)
                .map_err(|err| git2::Error::from_str(&format!(
                    "Failed to read orig_head file: {}", err
                )))?;
            let orig_commit_id = content.trim();
            let orig_commit = repo.find_commit(git2::Oid::from_str(orig_commit_id)?)?;
            let branches = repo.branches(None)?;

            for branch in branches {
                let (branch_ref, _) = branch?;
                let branch_commit = repo.reference_to_annotated_commit(&branch_ref.get())?;
                
                if orig_commit.id() == branch_commit.id() {
                    branch_name = match branch_ref.name() {
                        Ok(Some(name)) => name.to_string(),
                        Ok(None) | Err(_) => return Err(git2::Error::from_str("Unable to determine branch name"))
                    };
                    break;
                }
            }
        }
        
        format!("+refs/heads/{}", branch_name)
    };

    _log(
        Arc::clone(&log_callback),
        LogType::ForcePush,
        "Force pushing changes".to_string(),
    );

    remote.push(&[&refname], Some(&mut push_options)).unwrap();

    _log(
        Arc::clone(&log_callback),
        LogType::ForcePush,
        "Force push successful".to_string(),
    );

    Ok(())
}

pub async fn download_and_overwrite(
    path_string: String,
    remote_name: String,
    provider: String,
    credentials: (String, String),
    author: (String, String),
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::ForcePull,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(&path_string)?;
    set_author(&repo, &author);
    repo.cleanup_state();
    
    let mut remote = repo.find_remote(&remote_name)?;

    let callbacks = get_default_callbacks(Some(&provider), Some(&credentials));
    let mut fetch_options = FetchOptions::new();
    fetch_options.prune(git2::FetchPrune::On);
    fetch_options.update_fetchhead(true);
    fetch_options.remote_callbacks(callbacks);
    fetch_options.download_tags(git2::AutotagOption::All);

    _log(
        Arc::clone(&log_callback),
        LogType::ForcePull,
        "Force fetching changes".to_string(),
    );

    remote.fetch::<&str>(&[], Some(&mut fetch_options), None)?;

    let fetch_commit = repo
        .find_reference("FETCH_HEAD")
        .and_then(|r| repo.reference_to_annotated_commit(&r))?;


    let git_dir = repo.path();
    let rebase_head_path = git_dir.join("rebase-merge").join("head-name");
    let refname = if rebase_head_path.exists() {
        let content = fs::read_to_string(&rebase_head_path)
            .map_err(|err| git2::Error::from_str(&format!(
                "Failed to read rebase head-name file: {}", err
            )))?;
        
        content.trim().to_string()
    } else {
        let head = repo.head()?;
        let resolved_head = head.resolve()?;
        let mut branch_name = resolved_head.shorthand()
            .ok_or_else(|| git2::Error::from_str("Could not determine branch name"))?
            .to_string();

        let orig_head_path = git_dir.join("ORIG_HEAD");
        if branch_name == "HEAD" && orig_head_path.exists() {
            let content = fs::read_to_string(&orig_head_path)
                .map_err(|err| git2::Error::from_str(&format!(
                    "Failed to read orig_head file: {}", err
                )))?;
            let orig_commit_id = content.trim();
            let orig_commit = repo.find_commit(git2::Oid::from_str(orig_commit_id)?)?;
            let branches = repo.branches(None)?;

            for branch in branches {
                let (branch_ref, _) = branch?;
                let branch_commit = repo.reference_to_annotated_commit(&branch_ref.get())?;
                
                if orig_commit.id() == branch_commit.id() {
                    branch_name = match branch_ref.name() {
                        Ok(Some(name)) => name.to_string(),
                        Ok(None) | Err(_) => return Err(git2::Error::from_str("Unable to determine branch name"))
                    };
                    break;
                }
            }
        }
        
        format!("refs/heads/{}", branch_name)
    };

    let mut reference = repo.find_reference(&refname)?;
    reference.set_target(fetch_commit.id(), "force pull")?;
    repo.set_head(&refname)?;
    repo.checkout_head(Some(
        git2::build::CheckoutBuilder::new()
            .force()
            .allow_conflicts(true)
            .conflict_style_merge(true),
    ))?;

    _log(
        Arc::clone(&log_callback),
        LogType::ForcePull,
        "Force pull successful".to_string(),
    );

    Ok(())
}

pub async fn discard_changes(
    path_string: &String,
    file_paths: Vec<String>,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(path_string)?;

    let mut checkout = git2::build::CheckoutBuilder::new();
    checkout.force();
    for file_path in &file_paths {
        checkout.path(file_path);
    }

    repo.checkout_head(Some(&mut checkout))?;
    Ok(())
}

pub async fn get_conflicting(
    path_string: &String,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Vec<String> {    
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    let repo = match Repository::open(path_string) {
        Ok(repo) => repo,
        Err(_) => return Vec::new(),
    };

    let index = repo.index().unwrap();
    let mut conflicts = Vec::new();

    index.conflicts().unwrap().for_each(|conflict| {
        if let Ok(conflict) = conflict {
            if let Some(ours) = conflict.our {
                conflicts.push(String::from_utf8_lossy(&ours.path).to_string());
            }
            if let Some(theirs) = conflict.their {
                conflicts.push(String::from_utf8_lossy(&theirs.path).to_string());
            }
        }
    });

    conflicts
}

pub async fn get_staged_file_paths(
    path_string: &str, 
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Vec<(String, i32)> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    let repo = match Repository::open(path_string) {
        Ok(repo) => repo,
        Err(_) => return Vec::new(),
    };

    get_staged_file_paths_priv(&repo, &log_callback)
}

fn get_staged_file_paths_priv(
    repo: &Repository,
    log_callback: &Arc<impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static>,
) -> Vec<(String, i32)> {
    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting staged files".to_string(),
    );

    let mut opts = StatusOptions::new();
    opts.include_untracked(false);
    opts.include_ignored(false);
    opts.update_index(true);
    opts.show(git2::StatusShow::Index);
    let statuses = repo.statuses(Some(&mut opts)).unwrap();

    let mut file_paths = Vec::new();

    for entry in statuses.iter() {
        let path = entry.path().unwrap_or_default();
        let status = entry.status();

        if path.ends_with('/') && repo.find_submodule(&path[..path.len()-1]).is_ok() {
            continue;
        }

        if let Ok(mut submodule) = repo.find_submodule(path) {
            submodule.reload(true).ok();
            let head_oid = submodule.head_id();
            let index_oid = submodule.index_id();

            if head_oid != index_oid {
                file_paths.push((path.to_string(), 1));
            }
            continue;
        }

        match status {
            Status::INDEX_MODIFIED => {
                file_paths.push((path.to_string(), 1));
            },
            Status::INDEX_DELETED => {
                file_paths.push((path.to_string(), 2));
            },
            Status::INDEX_NEW => {
                file_paths.push((path.to_string(), 3));
            },
            _ => {}
        }
    }

    file_paths
}

pub async fn get_uncommitted_file_paths(
    path_string: &str, 
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Vec<(String, i32)> {
    init(None);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    let repo = match Repository::open(path_string) {
        Ok(repo) => repo,
        Err(_) => return Vec::new(),
    };

    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    
    get_uncommitted_file_paths_priv(&repo, true, &log_callback)
}

fn get_uncommitted_file_paths_priv(
    repo: &Repository,
    include_untracked: bool, 
    log_callback: &Arc<impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static>,
) -> Vec<(String, i32)> {
    let mut opts = StatusOptions::new();
    opts.include_untracked(include_untracked);
    opts.include_ignored(false);
    opts.update_index(true);
    let statuses = repo.statuses(Some(&mut opts)).unwrap();

    let mut file_paths = Vec::new();


    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting uncommitted file paths".to_string(),
    );

    for entry in statuses.iter() {
        let path = entry.path().unwrap_or_default();
        let status = entry.status();

        if path.ends_with('/') && repo.find_submodule(&path[..path.len()-1]).is_ok() {
            continue;
        }

        if let Ok(mut submodule) = repo.find_submodule(path) {
            submodule.reload(true).ok();
            let head_oid = submodule.head_id();
            let index_oid = submodule.index_id();
            let workdir_oid = submodule.workdir_id();

            if head_oid != index_oid || head_oid != workdir_oid {
                file_paths.push((path.to_string(), 1)); // Submodule ref changed
            }
            continue;
        }

        match status {
            Status::WT_MODIFIED => {
                file_paths.push((path.to_string(), 1)); // Change
            },
            Status::WT_DELETED => {
                file_paths.push((path.to_string(), 2)); // Deletion
            },
            Status::WT_NEW => {
                file_paths.push((path.to_string(), 3)); // Addition
            },
            _ => {}
        }
    }

    file_paths
}

pub async fn abort_merge(
    path_string: &String,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    let log_callback = Arc::new(log);

    let repo = Repository::open(path_string)?;
    let merge_head_path = repo.path().join("MERGE_HEAD");

    _log(
        Arc::clone(&log_callback),
        LogType::Global,
        format!("path: {}", merge_head_path.to_string_lossy()),
    );

    if Path::new(&merge_head_path).exists() {
        _log(
            Arc::clone(&log_callback),
            LogType::Global,
            "merge head exists".to_string(),
        );
        let head = repo.head()?.peel_to_commit()?;
        repo.reset(head.as_object(), ResetType::Hard, None)?;
        repo.cleanup_state()?;
    }

    if repo.state() == RepositoryState::Merge
        || repo.state() == RepositoryState::Rebase
        || repo.state() == RepositoryState::RebaseMerge
    {
        _log(
            Arc::clone(&log_callback),
            LogType::Global,
            "rebase exists".to_string(),
        );

        let rebase_merge_path = repo.path().join("rebase-merge/msgnum");
        if rebase_merge_path.exists() && fs::metadata(&rebase_merge_path).unwrap().len() == 0 {
            fs::remove_file(&rebase_merge_path).unwrap();
        }

        let mut rebase = repo.open_rebase(None)?;
        rebase.abort()?;
    }

    Ok(())
}

pub async fn generate_ssh_key(
    format: &str,
    passphrase: &str,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> (String, String) {
    let log_callback = Arc::new(log);
    
    _log(
        Arc::clone(&log_callback),
        LogType::Global,
        "Generating Keys".to_string(),
    );

    let key_pair = KeyPair::generate(KeyType::ED25519, 256).unwrap();

    let private_key = key_pair
        .serialize_openssh(
            if passphrase.is_empty() {
                None
            } else {
                Some(passphrase)
            }, 
            osshkeys::cipher::Cipher::Null
        )
        .unwrap();

    let public_key = key_pair.serialize_publickey().unwrap();

    (private_key, public_key)
}

pub async fn get_branch_name(
    path_string: &String,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Option<String> {
    let log_callback = Arc::new(log);

    let repo = Repository::open(Path::new(path_string)).unwrap();
    let branch_name = get_branch_name_priv(&repo);

    if branch_name == None {
        _log(
            Arc::clone(&log_callback),
            LogType::Global,
            "Failed to get HEAD".to_string(),
        );
    }

    return branch_name;
}


fn get_branch_name_priv(
    repo: &Repository,
) -> Option<String> {

    let head = match repo.head() {
        Ok(h) => h,
        Err(_) => {
            return None;
        }
    };

    if head.is_branch() {
        return Some(head.shorthand().unwrap().to_string());
    } else if let Some(name) = head.name() {
        if name.starts_with("refs/remotes/") {
            return Some(name.trim_start_matches("refs/remotes/").to_string());
        }
    } 
    
    None
}

pub async fn get_branch_names(
    path_string: &String,
    remote: &String,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Vec<String> {
    let log_callback = Arc::new(log);
    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(Path::new(path_string)).unwrap();

    let mut branch_set = std::collections::HashSet::new();
    
    let local_branches = repo.branches(Some(BranchType::Local)).unwrap();
    for branch_result in local_branches {
        if let Ok((branch, _)) = branch_result {
            if let Some(name) = branch.name().ok().flatten() {
                branch_set.insert(name.to_string());
            }
        }
    }
    
    let remote_branches = repo.branches(Some(BranchType::Remote)).unwrap();
    for branch_result in remote_branches {
        if let Ok((branch, _)) = branch_result {
            if let Some(name) = branch.name().ok().flatten() {
                if name.contains("HEAD") {
                    continue;
                }
                
                if let Some(stripped_name) = name.strip_prefix(&format!("{}/", remote.to_string())) {
                    if !branch_set.contains(stripped_name) {
                        branch_set.insert(stripped_name.to_string());
                    }
                } else {
                    branch_set.insert(name.to_string());
                }
            }
        }
    }
    
    branch_set.into_iter().collect()
}

pub async fn set_remote_url(
    path_string: &String,
    remote_name: &String,
    new_remote_url: &String,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(Path::new(path_string)).unwrap();
    repo.remote_set_url(&remote_name, &new_remote_url)?;
    
    Ok(())
}

pub async fn checkout_branch(
    path_string: &String,
    remote: &String,
    branch_name: &String,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::GitStatus,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(Path::new(path_string)).unwrap();
    let branch = match repo.find_branch(&branch_name, git2::BranchType::Local) {
        Ok(branch) => branch,
        Err(e) => {
            if e.code() == ErrorCode::NotFound {                

                let remote_branch_name = format!("{}/{}", remote, branch_name);
                let remote_branch = repo.find_branch(&remote_branch_name, git2::BranchType::Remote)?;
                let target = remote_branch.get().target().ok_or_else(|| git2::Error::from_str("Invalid remote branch"))?;
                repo.branch(branch_name, &repo.find_commit(target)?, false)?

                // match repo.find_branch(&format!("{}/{}", &remote, &branch_name), git2::BranchType::Remote).unwrap() {
                //     Some(remote_branch) => {
                        

                //         remote_branch
                //     },
                //     None => return Err(Error::from_str(&format!("Branch '{}' not found", branch_name)))
                // }
            } else {
                return Err(e);
            }
        }
    };
    
    // Get the commit that the branch points to
    let object = branch.get().peel(git2::ObjectType::Commit)?;
    // let commit = object.as_commit().ok_or_else(|| {
    //     git2::Error::from_str("Could not find commit for branch")
    // })?;
    
    // Create a checkout builder
    let mut checkout_builder = git2::build::CheckoutBuilder::new();
    checkout_builder.force(); // Force checkout (discarding local changes)
    
    // Set HEAD to the branch's commit
    repo.checkout_tree(&object, Some(&mut checkout_builder))?;
    
    // Update HEAD ref to point to the branch
    // let refname = branch.get().name().ok_or_else(|| {
    //     git2::Error::from_str("Could not get branch reference name")
    // })?;
    
    // repo.set_head(refname)?;

    let refname = format!("refs/heads/{}", branch_name);
    repo.set_head(&refname)?;
    
    Ok(())
}

pub async fn get_disable_ssl(git_dir: &str) -> bool {
    if let Ok(repo) = Repository::open(git_dir) {
        if let Ok(config) = repo.config() {
            if let Ok(value) = config.get_string("http.sslVerify") {
                return value.eq_ignore_ascii_case("false");
            }
        }
    }
    false
}

pub async fn set_disable_ssl(git_dir: &str, disable: bool) {
    if let Ok(repo) = Repository::open(git_dir) {
        if let Ok(mut config) = repo.config() {
            let value = if disable { "false" } else { "true" };
            let _ = config.set_str("http.sslVerify", value);
        }
    }
}

pub async fn create_branch(
    path_string: &String,
    new_branch_name: &String,
    remote_name: &String,
    provider: &String,
    credentials: &(String, String),
    source_branch_name: &String,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::Global,
        format!("Creating new branch '{}' from '{}'", new_branch_name, source_branch_name),
    );

    let repo = Repository::open(Path::new(path_string))?;
    
    let current_branch = get_branch_name_priv(&repo);
    
    // If we're not on the source branch, check it out first
    if current_branch.as_deref() != Some(source_branch_name) {
        checkout_branch(path_string, &remote_name, source_branch_name, |_level: LogType, _msg: String| Box::pin(async {})).await?;
    }

    // Get the commit that the source branch points to
    let source_branch = repo.find_branch(source_branch_name, BranchType::Local)?;
    let source_commit = source_branch.get().peel_to_commit()?;

    // Create the new branch pointing to the same commit
    let new_branch = repo.branch(new_branch_name, &source_commit, false)?;
    
    _log(
        Arc::clone(&log_callback),
        LogType::Global,
        format!("New branch '{}' created", new_branch_name),
    );

    // Check out the new branch
    let object = new_branch.get().peel(git2::ObjectType::Commit)?;
    
    let mut checkout_builder = git2::build::CheckoutBuilder::new();
    checkout_builder.force();
    
    repo.checkout_tree(&object, Some(&mut checkout_builder))?;
    
    let refname = format!("refs/heads/{}", new_branch_name);
    repo.set_head(&refname)?;

    _log(
        Arc::clone(&log_callback),
        LogType::Global,
        format!("Switched to new branch '{}'", new_branch_name),
    );
    
    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        format!("Pushing new branch '{}' to remote", new_branch_name),
    );
    
    let mut remote = repo.find_remote(remote_name)?;
    let callbacks = get_default_callbacks(Some(provider), Some(credentials));
    
    let mut push_options = PushOptions::new();
    push_options.remote_callbacks(callbacks);
    
    let refspec = format!("refs/heads/{}:refs/heads/{}", new_branch_name, new_branch_name);
    
    match remote.push(&[&refspec], Some(&mut push_options)) {
        Ok(_) => {
            _log(
                Arc::clone(&log_callback),
                LogType::PushToRepo,
                format!("Successfully pushed branch '{}' to remote", new_branch_name),
            );
        },
        Err(e) => {
            _log(
                Arc::clone(&log_callback),
                LogType::PushToRepo,
                format!("Failed to push branch '{}' to remote: {}", new_branch_name, e),
            );
            return Err(e);
        }
    }
    
    // Set the upstream branch for the new branch
    let mut branch = repo.find_branch(new_branch_name, BranchType::Local)?;
    let upstream_name = format!("{}/{}", remote_name, new_branch_name);
    branch.set_upstream(Some(&upstream_name))?;
    
    _log(
        Arc::clone(&log_callback),
        LogType::Global,
        format!("Set upstream for '{}' to '{}'", new_branch_name, upstream_name),
    );
    
    Ok(())
}