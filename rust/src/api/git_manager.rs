use flutter_rust_bridge::DartFnFuture;
use git2::{
    BranchType, CertificateCheckStatus, Cred, DiffOptions, ErrorCode, FetchOptions, PushOptions,
    RemoteCallbacks, Repository, RepositoryState, ResetType, Signature, Status, StatusOptions,
    SubmoduleUpdateOptions, Tree,
};
use osshkeys::{KeyPair, KeyType};
use ssh_key::{HashAlg, LineEnding, PrivateKey};
use std::{
    collections::HashMap,
    env, fs,
    path::{Path, PathBuf},
    sync::{
        atomic::{AtomicBool, AtomicU64, Ordering},
        Arc, Mutex,
    },
    time::Instant,
};
use uuid::Uuid;

pub struct Commit {
    pub timestamp: i64,
    pub author_username: String,
    pub author_email: String,
    pub reference: String,
    pub commit_message: String,
    pub additions: i32,
    pub deletions: i32,
    pub unpulled: bool,
    pub unpushed: bool,
}

#[derive(Debug, Default)]
pub struct Diff {
    pub insertions: i32,
    pub deletions: i32,
    pub diff_parts: HashMap<String, HashMap<String, String>>,
}

// Also add to lib/api/logger.dart:21
pub enum LogType {
    TEST,

    Global,
    AccessibilityService,

    SelectDirectory,
    GetRepos,
    Sync,
    SyncException,

    Clone,
    UpdateSubmodules,
    FetchRemote,
    PullFromRepo,
    Stage,
    Unstage,
    RecommendedAction,
    Commit,
    PushToRepo,
    ForcePull,
    ForcePush,
    DownloadAndOverwrite,
    UploadAndOverwrite,
    DiscardChanges,
    UntrackAll,
    CommitDiff,
    FileDiff,
    RecentCommits,
    ConflictingFiles,
    UncommittedFiles,
    StagedFiles,
    AbortMerge,
    BranchName,
    BranchNames,
    SetRemoteUrl,
    CheckoutBranch,
    CreateBranch,
    ReadGitIgnore,
    WriteGitIgnore,
    ReadGitInfoExclude,
    WriteGitInfoExclude,
    GetDisableSsl,
    SetDisableSsl,
    GenerateKeyPair,
    GetRemoteUrlLink,
    DiscardDir,
    DiscardGitIndex,
    DiscardFetchHead,
    PruneCorruptedObjects,
    GetSubmodules,
    HasGitFilters,
    DownloadChanges,
    UploadChanges,
}

trait WithLine {
    fn safe_wline(self, line: u32) -> Result<Self, git2::Error>
    where
        Self: Sized;
}

impl<T> WithLine for Result<T, git2::Error> {
    fn safe_wline(self, line: u32) -> Result<Self, git2::Error> {
        Ok(self.map_err(|e| git2::Error::from_str(&format!("{} (at line {})", e.message(), line))))
    }
}

macro_rules! swl {
    ($expr:expr) => {
        ($expr).safe_wline(line!())?
    };
}

pub async fn commit_list_run_with_lock(
    queue_dir: &str,
    index: i32,
    priority: i32,
    fn_name: &str,
    function: impl Fn() -> DartFnFuture<Option<Vec<Commit>>> + Send + Sync + 'static,
) -> Result<Option<Vec<Commit>>, git2::Error> {
    run_with_lock(queue_dir, index, priority, fn_name, function).await
}

pub async fn string_list_run_with_lock(
    queue_dir: &str,
    index: i32,
    priority: i32,
    fn_name: &str,
    function: impl Fn() -> DartFnFuture<Option<Vec<String>>> + Send + Sync + 'static,
) -> Result<Option<Vec<String>>, git2::Error> {
    run_with_lock(queue_dir, index, priority, fn_name, function).await
}

pub async fn string_int_list_run_with_lock(
    queue_dir: &str,
    index: i32,
    priority: i32,
    fn_name: &str,
    function: impl Fn() -> DartFnFuture<Option<Vec<(String, i32)>>> + Send + Sync + 'static,
) -> Result<Option<Vec<(String, i32)>>, git2::Error> {
    run_with_lock(queue_dir, index, priority, fn_name, function).await
}

// pub async fn string_map_stream_run_with_lock(
//     sink: StreamSink<(String, HashMap<String, String>)>,
//     queue_dir: &str,
//     index: i32,
//     priority: i32,
//     function: impl Fn() -> DartFnFuture<Option<StreamSink<(String, HashMap<String, String>)>>>
//         + Send
//         + Sync
//         + 'static,
// ) -> Result<(), git2::Error> {
//     Ok(())
//     // run_with_lock(queue_dir, index, priority, function).await
// }

pub async fn string_pair_run_with_lock(
    queue_dir: &str,
    index: i32,
    priority: i32,
    fn_name: &str,
    function: impl Fn() -> DartFnFuture<Option<(String, String)>> + Send + Sync + 'static,
) -> Result<Option<(String, String)>, git2::Error> {
    run_with_lock(queue_dir, index, priority, fn_name, function).await
}

pub async fn string_run_with_lock(
    queue_dir: &str,
    index: i32,
    priority: i32,
    fn_name: &str,
    function: impl Fn() -> DartFnFuture<Option<String>> + Send + Sync + 'static,
) -> Result<Option<String>, git2::Error> {
    run_with_lock(queue_dir, index, priority, fn_name, function).await
}

pub async fn int_run_with_lock(
    queue_dir: &str,
    index: i32,
    priority: i32,
    fn_name: &str,
    function: impl Fn() -> DartFnFuture<Option<i32>> + Send + Sync + 'static,
) -> Result<Option<i32>, git2::Error> {
    run_with_lock(queue_dir, index, priority, fn_name, function).await
}

pub async fn bool_run_with_lock(
    queue_dir: &str,
    index: i32,
    priority: i32,
    fn_name: &str,
    function: impl Fn() -> DartFnFuture<Option<bool>> + Send + Sync + 'static,
) -> Result<Option<bool>, git2::Error> {
    run_with_lock(queue_dir, index, priority, fn_name, function).await
}

pub async fn void_run_with_lock(
    queue_dir: &str,
    index: i32,
    priority: i32,
    fn_name: &str,
    function: impl Fn() -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    run_with_lock(queue_dir, index, priority, fn_name, function).await
}

async fn run_with_lock<T: Default>(
    queue_dir: &str,
    index: i32,
    priority: i32,
    fn_name: &str,
    function: impl Fn() -> DartFnFuture<T> + Send + Sync + 'static,
) -> Result<T, git2::Error> {
    use nix::fcntl::{Flock, FlockArg};
    use std::fs;
    use std::io::{Read, Seek, SeekFrom, Write};
    init(None);

    let queues_dir = format!("{}/queues", queue_dir);
    fs::create_dir_all(&queues_dir)
        .map_err(|e| git2::Error::from_str(&format!("Failed to create queues directory: {}", e)))?;

    let queue_file_path = format!("{}/flock_queue_{}", queues_dir, index);

    let identifier = format!(
        "{}:{}:{}",
        priority,
        fn_name.to_string(),
        Uuid::new_v4().to_string()
    );

    let initial_file = fs::OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .open(&queue_file_path)
        .map_err(|e| git2::Error::from_str(&format!("Failed to open queue file: {}", e)))?;

    let mut flock = match Flock::lock(initial_file, FlockArg::LockExclusive) {
        Ok(flock) => flock,
        Err((_file, err)) => {
            return Err(git2::Error::from_str(&format!(
                "Error locking file: {}",
                err
            )))
        }
    };

    let mut queue_contents = String::new();

    flock
        .read_to_string(&mut queue_contents)
        .map_err(|e| git2::Error::from_str(&format!("Failed to read queue file: {}", e)))?;

    let mut queue_entries: Vec<_> = queue_contents
        .split('\n')
        .filter(|entry| !entry.trim().is_empty())
        .collect();

    let new_priority: i32 = priority;
    if new_priority == 1 {
        queue_entries = queue_entries
            .into_iter()
            .enumerate()
            .filter(|(i, entry)| {
                if *i == 0 {
                    true
                } else {
                    let parts: Vec<&str> = entry.split(':').collect();
                    if parts.len() >= 2 {
                        parts[0] != "1" || parts[1] != fn_name
                    } else {
                        true
                    }
                }
            })
            .map(|(_, e)| e)
            .collect();
    }

    let insert_index = queue_entries
        .iter()
        .enumerate()
        .skip(1)
        .find(|(_, entry)| {
            let entry_priority: i32 = entry.split(':').next().unwrap_or("0").parse().unwrap_or(0);
            new_priority > entry_priority
        })
        .map(|(idx, _)| idx)
        .unwrap_or(queue_entries.len());

    let final_insert_index = if queue_entries.len() > 0 {
        std::cmp::max(1, insert_index)
    } else {
        0
    };

    if final_insert_index > queue_entries.len() {
        queue_entries.push(&identifier);
    } else {
        queue_entries.insert(final_insert_index, &identifier);
    }

    flock
        .seek(SeekFrom::Start(0))
        .map_err(|e| git2::Error::from_str(&format!("Failed to seek queue file: {}", e)))?;
    flock
        .set_len(0)
        .map_err(|e| git2::Error::from_str(&format!("Failed to truncate queue file: {}", e)))?;
    flock
        .write_all(queue_entries.join("\n").as_bytes())
        .map_err(|e| git2::Error::from_str(&format!("Failed to write queue file: {}", e)))?;

    flock.unlock().map_err(|(_, e)| {
        git2::Error::from_str(&format!("Failed to unlock queue file: {}", e))
    })?;

    const QUEUE_TIMEOUT_SECS: u64 = 600;
    let start_time = std::time::Instant::now();

    loop {
        if start_time.elapsed().as_secs() >= QUEUE_TIMEOUT_SECS {
            let timeout_file = match fs::OpenOptions::new()
                .read(true)
                .write(true)
                .open(&queue_file_path)
            {
                Ok(f) => f,
                Err(_) => return Ok(T::default()),
            };

            let mut timeout_flock = match Flock::lock(timeout_file, FlockArg::LockExclusive) {
                Ok(f) => f,
                Err(_) => return Ok(T::default()),
            };

            let mut queue_contents = String::new();
            if timeout_flock.read_to_string(&mut queue_contents).is_err() {
                let _ = timeout_flock.unlock();
                return Ok(T::default());
            }

            let queue_entries: Vec<_> = queue_contents
                .split('\n')
                .filter(|entry| {
                    *entry != identifier && !entry.trim().is_empty()
                })
                .collect();

            let _ = timeout_flock.seek(SeekFrom::Start(0));
            let _ = timeout_flock.set_len(0);
            let _ = timeout_flock.write_all(queue_entries.join("\n").as_bytes());
            let _ = timeout_flock.unlock();

            return Err(git2::Error::from_str(&format!(
                "Timeout after {} seconds waiting for queue position",
                QUEUE_TIMEOUT_SECS
            )));
        }

        let read_file = match fs::OpenOptions::new().read(true).open(&queue_file_path) {
            Ok(f) => f,
            Err(_) => return Ok(T::default()),
        };

        let mut read_flock = match Flock::lock(read_file, FlockArg::LockExclusive) {
            Ok(read_flock) => read_flock,
            Err(_) => return Ok(T::default()),
        };

        let mut string = String::new();
        read_flock.read_to_string(&mut string).unwrap_or(0);

        if !string.contains(&*identifier) {
            let _ = read_flock.unlock();
            return Ok(T::default());
        }

        if string.starts_with(&identifier) {
            let _ = read_flock.unlock();
            break;
        }

        let _ = read_flock.unlock();

        tokio::time::sleep(std::time::Duration::from_millis(100)).await;
    }

    struct QueueCleanupGuard {
        queue_file_path: String,
        identifier: String,
    }

    impl Drop for QueueCleanupGuard {
        fn drop(&mut self) {
            let cleanup = || -> Result<(), Box<dyn std::error::Error>> {
                let mut flock = match Flock::lock(
                    fs::OpenOptions::new()
                        .read(true)
                        .write(true)
                        .open(&self.queue_file_path)?,
                    FlockArg::LockExclusive,
                ) {
                    Ok(flock) => flock,
                    Err((_file, err)) => return Err(Box::new(err)),
                };

                let mut queue_contents = String::new();
                flock.read_to_string(&mut queue_contents)?;

                let queue_entries: Vec<_> = queue_contents
                    .split('\n')
                    .filter(|entry| {
                        *entry != self.identifier && !entry.trim().is_empty()
                    })
                    .collect();

                flock.seek(SeekFrom::Start(0))?;
                flock.set_len(0)?;
                flock.write_all(queue_entries.join("\n").as_bytes())?;
                if let Err((_, err)) = flock.unlock() {
                    return Err(Box::new(err) as Box<dyn std::error::Error>);
                }
                Ok(())
            };

            if let Err(e) = cleanup() {
                eprintln!("Warning: failed to cleanup queue entry: {}", e);
            }
        }
    }

    let _guard = QueueCleanupGuard {
        queue_file_path: queue_file_path.clone(),
        identifier: identifier.clone(),
    };

    let result = function().await;

    Ok(result)
}

pub async fn is_locked(queue_dir: &str, index: i32) -> Result<bool, git2::Error> {
    use nix::fcntl::{Flock, FlockArg};
    use std::fs;
    use std::io::Read;
    let queue_file_path = format!("{}/queues/flock_queue_{}", queue_dir, index);

    let mut read_flock = match Flock::lock(
        fs::OpenOptions::new()
            .read(true)
            .open(&queue_file_path)
            .map_err(|e| git2::Error::from_str(&format!("Error opening queue file: {}", e)))?,
        FlockArg::LockExclusive,
    ) {
        Ok(flock) => flock,
        Err((_file, err)) => {
            return Err(git2::Error::from_str(&format!(
                "Error locking file for reading: {}",
                err
            )))
        }
    };

    let mut queue_contents = String::new();
    read_flock
        .read_to_string(&mut queue_contents)
        .map_err(|e| git2::Error::from_str(&format!("Error reading queue file: {}", e)))?;

    let queue_entries: Vec<&str> = queue_contents
        .split('\n')
        .filter(|entry| !entry.trim().is_empty())
        .collect();

    if let Some(first_entry) = queue_entries.get(0) {
        let parts: Vec<&str> = first_entry.split(':').collect();
        if !parts.is_empty() {
            let priority: i32 = parts[0].parse().unwrap_or(0);
            return Ok(priority == 3);
        }
    }

    Ok(false)
}

pub fn init(homepath: Option<String>) {
    if let Some(path) = homepath {
        unsafe { env::set_var("RUST_BACKTRACE", "1") };
        unsafe { env::set_var("HOME", path) };
    }

    flutter_rust_bridge::setup_default_user_utils();

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
    config.set_str("user.name", &author.0).unwrap();
    config.set_str("user.email", &author.1).unwrap();
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

pub async fn get_submodule_paths(path_string: String) -> Result<Vec<String>, git2::Error> {
    let repo = swl!(Repository::open(path_string))?;
    let mut paths = Vec::new();

    for mut submodule in swl!(repo.submodules())? {
        swl!(submodule.reload(false))?;
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
    let clone_task_callback = Arc::new(clone_task_callback);
    let clone_progress_callback = Arc::new(clone_progress_callback);
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::Clone,
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
    let repo = swl!(builder.clone(url.as_str(), path))?;

    set_author(&repo, &author);
    repo.cleanup_state().unwrap();

    let mut remote = repo.find_remote("origin")?;
    let callbacks = get_default_callbacks(Some(&provider), Some(&credentials));
    let mut fo2 = FetchOptions::new();
    fo2.update_fetchhead(true);
    fo2.remote_callbacks(callbacks);
    let _ = remote.fetch::<&str>(&[], Some(&mut fo2), None);

    _log(
        Arc::clone(&log_callback),
        LogType::Clone,
        "Repository cloned successfully".to_string(),
    );

    swl!(swl!(repo.submodules())?.iter_mut().try_for_each(|sm| {
        let sm_name = sm.name().unwrap_or("unknown").to_string();

        _log(
            Arc::clone(&log_callback),
            LogType::Clone,
            format!("Processing submodule: {}", sm_name),
        );

        let mut options = SubmoduleUpdateOptions::new();
        let mut fetch_opts = FetchOptions::new();
        fetch_opts.remote_callbacks(get_default_callbacks(Some(&provider), Some(&credentials)));
        fetch_opts.prune(git2::FetchPrune::On);
        options.fetch(fetch_opts);
        options.allow_fetch(true);

        swl!(sm.init(true))?;
        swl!(sm.update(true, Some(&mut options)))?;

        let sm_repo_result = sm.open();
        if let Ok(sm_repo) = sm_repo_result {
            if let Ok(head) = sm_repo.head() {
                if let Some(target_commit_id) = head.target() {
                    _log(
                        Arc::clone(&log_callback),
                        LogType::Clone,
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
                                                        LogType::Clone,
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
                                                                        LogType::Clone,
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
                                                                LogType::Clone,
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
                            LogType::Clone,
                            format!("No branch found containing commit in submodule {}, staying in detached HEAD", sm_name),
                        );
                    }
                }
            }
        }

        Ok::<(), git2::Error>(())
    }))?;

    set_author(&repo, &author);
    repo.cleanup_state().unwrap();

    _log(
        Arc::clone(&log_callback),
        LogType::Clone,
        "Submodules updated successfully".to_string(),
    );

    Ok(())
}

pub async fn untrack_all(
    path_string: &String,
    file_paths: Option<Vec<String>>,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::Stage,
        "Getting local directory".to_string(),
    );

    let repo = swl!(Repository::open(path_string))?;
    let mut index = swl!(repo.index())?;

    let mut paths_to_remove: Vec<String> = if let Some(ref paths) = file_paths {
        paths.clone()
    } else {
        Vec::new()
    };

    if file_paths.is_none() {
        if let Ok(contents) = fs::read_to_string(format!("{}/.gitignore", path_string)) {
            for line in contents.lines() {
                let trimmed = line.trim();
                if !trimmed.is_empty() && !trimmed.starts_with('#') {
                    paths_to_remove.push(trimmed.to_string());
                }
            }
        }

        if let Ok(contents) = fs::read_to_string(format!("{}/.git/info/exclude", path_string)) {
            for line in contents.lines() {
                let trimmed = line.trim();
                if !trimmed.is_empty() && !trimmed.starts_with('#') {
                    paths_to_remove.push(trimmed.to_string());
                }
            }
        }
    }

    for path in paths_to_remove {
        swl!(index.remove_path(&PathBuf::from(path)))?;
    }

    swl!(index.write())?;
    if !index.has_conflicts() {
        swl!(index.write_tree())?;
    }

    _log(
        Arc::clone(&log_callback),
        LogType::Stage,
        "Untracked all!".to_string(),
    );

    Ok(())
}

pub async fn get_file_diff(
    path_string: &String,
    file_path: &String,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<Diff, git2::Error> {
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::FileDiff,
        "Opening repository".to_string(),
    );

    // Open the repository
    let repo = Repository::open(path_string)?;

    _log(
        Arc::clone(&log_callback),
        LogType::FileDiff,
        "Preparing diff options".to_string(),
    );

    let mut diff_opts = DiffOptions::new();
    diff_opts.pathspec(file_path);

    let mut file_diff = Diff::default();

    _log(
        Arc::clone(&log_callback),
        LogType::FileDiff,
        "Preparing revision walk".to_string(),
    );

    let mut revwalk = repo.revwalk()?;
    revwalk.push_head()?;
    revwalk.set_sorting(git2::Sort::TIME | git2::Sort::REVERSE)?;

    _log(
        Arc::clone(&log_callback),
        LogType::FileDiff,
        "Starting commit traversal".to_string(),
    );

    for commit_oid in revwalk {
        let commit_oid = commit_oid?;
        let commit = repo.find_commit(commit_oid)?;

        _log(
            Arc::clone(&log_callback),
            LogType::FileDiff,
            format!("Processing commit: {}", commit.id()),
        );

        let diff = if commit.parent_count() > 0 {
            let parent = commit.parent(0)?;
            repo.diff_tree_to_tree(
                Some(&parent.tree()?),
                Some(&commit.tree()?),
                Some(&mut diff_opts),
            )?
        } else {
            repo.diff_tree_to_tree(None, Some(&commit.tree()?), Some(&mut diff_opts))?
        };
        _log(
            Arc::clone(&log_callback),
            LogType::FileDiff,
            format!("Number of deltas: {}", diff.deltas().count()),
        );

        for delta in diff.deltas() {
            _log(
                Arc::clone(&log_callback),
                LogType::FileDiff,
                format!(
                    "Found file: {}",
                    delta
                        .new_file()
                        .path()
                        .and_then(|p| p.to_str())
                        .map(|s| s.to_string())
                        .unwrap_or_else(|| "Unknown".to_string())
                ),
            );
            if delta.new_file().path().map(|p| p.to_str()) == Some(Some(file_path)) {
                _log(
                    Arc::clone(&log_callback),
                    LogType::FileDiff,
                    format!("Found changes in file: {}", file_path),
                );

                let commit_hash = commit.id().to_string();
                let commit_timestamp = commit.time().seconds() * 1000;
                let commit_msg = commit.message().unwrap();
                let commit_identifier = format!(
                    "{}======={}======={}",
                    commit_timestamp, commit_hash, commit_msg
                );
                let mut commit_diff_parts = HashMap::new();

                let mut insertions = 0;
                let mut deletions = 0;

                let insertion_marker: &str = "+++++insertion+++++";
                let deletion_marker: &str = "-----deletion-----";

                diff.print(git2::DiffFormat::Patch, |_delta, hunk, line| {
                    let line_content = String::from_utf8_lossy(line.content()).to_string();

                    let hunk_header = hunk
                        .map(|h| String::from_utf8_lossy(h.header()).to_string())
                        .unwrap_or_else(|| "none".to_string());

                    match line.origin() {
                        '+' => {
                            insertions += 1;
                            commit_diff_parts
                                .entry(hunk_header.clone())
                                .and_modify(|existing_content| {
                                    *existing_content = format!(
                                        "{}{}{}",
                                        existing_content, insertion_marker, line_content
                                    );
                                })
                                .or_insert_with(|| format!("{}{}", insertion_marker, line_content));
                        }
                        '-' => {
                            deletions += 1;
                            commit_diff_parts
                                .entry(hunk_header.clone())
                                .and_modify(|existing_content| {
                                    *existing_content = format!(
                                        "{}{}{}",
                                        existing_content, deletion_marker, line_content
                                    );
                                })
                                .or_insert_with(|| format!("{}{}", deletion_marker, line_content));
                        }
                        ' ' => {
                            commit_diff_parts
                                .entry(hunk_header.clone())
                                .and_modify(|existing_content| {
                                    *existing_content =
                                        format!("{}{}", existing_content, line_content);
                                })
                                .or_insert_with(|| line_content.clone());
                        }
                        _ => {
                            _log(
                                Arc::clone(&log_callback),
                                LogType::FileDiff,
                                format!("Unhandled diff line origin: {}", line.origin()),
                            );
                        }
                    }

                    true
                })?;

                _log(
                    Arc::clone(&log_callback),
                    LogType::FileDiff,
                    format!(
                        "Commit {} - Insertions: {}, Deletions: {}",
                        commit_hash, insertions, deletions
                    ),
                );

                file_diff.insertions += insertions;
                file_diff.deletions += deletions;
                if !commit_diff_parts.is_empty() {
                    file_diff
                        .diff_parts
                        .insert(commit_identifier, commit_diff_parts);
                }
            }
        }
    }

    _log(
        Arc::clone(&log_callback),
        LogType::FileDiff,
        format!(
            "File history complete - Total Insertions: {}, Total Deletions: {}",
            file_diff.insertions, file_diff.deletions
        ),
    );

    Ok(file_diff)
}

pub async fn get_commit_diff(
    path_string: &String,
    start_ref: &String,
    end_ref: &Option<String>,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<Diff, git2::Error> {
    let log_callback = Arc::new(log);

    let insertion_marker: &str = "+++++insertion+++++";
    let deletion_marker: &str = "-----deletion-----";

    _log(
        Arc::clone(&log_callback),
        LogType::CommitDiff,
        "Getting local directory".to_string(),
    );

    let repo = swl!(Repository::open(path_string))?;

    let tree1 = swl!(repo.revparse_single(start_ref)?.peel_to_commit()?.tree())?;
    let tree2 = match end_ref {
        Some(end) => swl!(repo.revparse_single(end)?.peel_to_commit()?.tree())?,
        None => {
            let tree_builder = swl!(repo.treebuilder(None))?;
            let empty_tree_oid = swl!(tree_builder.write())?;
            swl!(repo.find_tree(empty_tree_oid))?
        }
    };

    let mut diff_opts = DiffOptions::new();

    let diff = swl!(repo.diff_tree_to_tree(Some(&tree2), Some(&tree1), Some(&mut diff_opts)))?;

    _log(
        Arc::clone(&log_callback),
        LogType::CommitDiff,
        "Getting diff stats".to_string(),
    );

    let diff_stats = swl!(diff.stats())?;

    _log(
        Arc::clone(&log_callback),
        LogType::CommitDiff,
        "Getting diff hunks".to_string(),
    );

    let diff_parts: Arc<Mutex<HashMap<String, HashMap<String, String>>>> =
        Arc::new(Mutex::new(HashMap::new()));
    swl!(diff.foreach(
        &mut |delta: git2::DiffDelta, _: f32| -> bool {
            let old_path = delta
                .old_file()
                .path()
                .map(|p| p.display().to_string())
                .unwrap_or_else(|| "Unknown".to_string());
            let new_path = delta
                .new_file()
                .path()
                .map(|p| p.display().to_string())
                .unwrap_or_else(|| "Unknown".to_string());

            let file_key = if old_path == new_path {
                new_path
            } else {
                format!("{}=>{}", old_path, new_path)
            };

            use git2::Delta;
            match delta.status() {
                Delta::Added | Delta::Copied | Delta::Renamed => {
                    let mut parts = diff_parts.lock().unwrap();
                    parts.entry(file_key).or_default();
                }
                _ => {}
            }

            true
        },
        None,
        Some(&mut |_: git2::DiffDelta, _: git2::DiffHunk| -> bool { true }),
        Some(&mut |delta: git2::DiffDelta,
                   hunk: Option<git2::DiffHunk>,
                   line: git2::DiffLine|
         -> bool {
            let old_file_path = delta
                .old_file()
                .path()
                .map(|p| p.display().to_string())
                .unwrap_or_else(|| "Unknown".to_string());
            let new_file_path = delta
                .new_file()
                .path()
                .map(|p| p.display().to_string())
                .unwrap_or_else(|| "Unknown".to_string());

            let mut hunk_header = "none".to_string();

            if let Some(hunk) = hunk {
                if !hunk.header().is_empty() {
                    hunk_header = String::from_utf8_lossy(hunk.header()).to_string();
                }
            }

            let file_path_key = if old_file_path == new_file_path {
                new_file_path
            } else {
                format!("{}=>{}", old_file_path, new_file_path)
            };

            let line_text = String::from_utf8_lossy(line.content()).to_string();

            let mut parts = diff_parts.lock().unwrap();
            match line.origin() {
                '+' => {
                    parts
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
                        .or_insert_with(|| {
                            format!("{}{}", &insertion_marker, line_text).to_string()
                        });
                }
                '-' => {
                    parts
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
                        .or_insert_with(|| {
                            format!("{}{}", &deletion_marker, line_text).to_string()
                        });
                }
                '>' => {}
                '<' => {}
                '=' => {}
                'F' => {}
                'H' => {}
                'B' => {}
                ' ' => {
                    parts
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
                }
                _ => {
                    _log(
                        Arc::clone(&log_callback),
                        LogType::CommitDiff,
                        format!("Other: {}", line.origin()),
                    );
                }
            }

            true
        })
    ))?;

    let diff_parts = diff_parts.lock().unwrap().clone();
    Ok(Diff {
        insertions: diff_stats.insertions() as i32,
        deletions: diff_stats.deletions() as i32,
        diff_parts: diff_parts,
    })
}

pub async fn get_recent_commits(
    path_string: &String,
    remote_name: &str,
    cached_diff_stats: HashMap<String, (i32, i32)>,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<Vec<Commit>, git2::Error> {
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::RecentCommits,
        "Getting local directory".to_string(),
    );

    let repo = swl!(Repository::open(path_string))?;
    let branch_name = get_branch_name_priv(&repo);
    let mut local_oid: Option<git2::Oid> = None;
    let mut remote_oid: Option<git2::Oid> = None;

    let mut revwalk = swl!(repo.revwalk())?;

    if let Some(name) = branch_name {
        let local_branch = swl!(repo.find_branch(&name, BranchType::Local))?;
        local_oid = Some(swl!(local_branch
            .get()
            .target()
            .ok_or_else(|| git2::Error::from_str("Invalid local branch")))?);
        let remote_ref = format!("refs/remotes/{}/{}", remote_name, name);
        remote_oid = repo.refname_to_id(&remote_ref).ok();
        if let Some(local_oid) = local_oid {
            swl!(revwalk.push(local_oid))?;
        }
        if let Some(remote_oid) = remote_oid {
            swl!(revwalk.push(remote_oid))?;
        }
    } else {
        match revwalk.push_head() {
            Ok(_) => {}
            Err(_) => return Ok(Vec::new()),
        }
    }

    // Build unpulled/unpushed OID sets via bounded revwalks
    let mut unpulled_oids = std::collections::HashSet::new();
    let mut unpushed_oids = std::collections::HashSet::new();

    if let (Some(l_oid), Some(r_oid)) = (local_oid, remote_oid) {
        // Unpulled: commits reachable from remote but not from local
        let mut rw = swl!(repo.revwalk())?;
        if rw.push(r_oid).is_ok() {
            let _ = rw.hide(l_oid);
            for oid_result in rw.take(50) {
                if let Ok(oid) = oid_result {
                    unpulled_oids.insert(oid);
                }
            }
        }

        // Unpushed: commits reachable from local but not from remote
        let mut rw = swl!(repo.revwalk())?;
        if rw.push(l_oid).is_ok() {
            let _ = rw.hide(r_oid);
            for oid_result in rw.take(50) {
                if let Ok(oid) = oid_result {
                    unpushed_oids.insert(oid);
                }
            }
        }
    }

    swl!(revwalk.set_sorting(git2::Sort::TOPOLOGICAL | git2::Sort::TIME))?;

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

        let author_username = commit.author().name().unwrap_or("<unknown>").to_string();
        let author_email = commit.author().email().unwrap_or("<unknown>").to_string();
        let time = commit.time().seconds();
        let message = commit
            .message()
            .unwrap_or("<no message>")
            .trim()
            .to_string();
        let reference = format!("{}", oid);

        let (additions, deletions) = if let Some(&(a, d)) = cached_diff_stats.get(&reference) {
            (a, d)
        } else {
            let parent = commit.parent(0).ok();
            let mut diff_opts = DiffOptions::new();
            let diff = match parent {
                Some(parent_commit) => repo.diff_tree_to_tree(
                    Some(&swl!(parent_commit.tree())?),
                    Some(&swl!(commit.tree())?),
                    Some(&mut diff_opts),
                )?,
                None => swl!(repo.diff_tree_to_tree(
                    None,
                    Some(&swl!(commit.tree())?),
                    Some(&mut diff_opts)
                ))?,
            };
            match diff.stats() {
                Ok(s) => (s.insertions() as i32, s.deletions() as i32),
                Err(_) => (0, 0),
            }
        };

        let unpulled = unpulled_oids.contains(&oid);
        let unpushed = unpushed_oids.contains(&oid);

        commits.push(Commit {
            timestamp: time,
            author_username,
            author_email,
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
    swl!(lb.set_target(rc.id(), &msg))?;
    swl!(repo.set_head(&name))?;
    swl!(repo.checkout_head(Some(
        git2::build::CheckoutBuilder::default()
            .allow_conflicts(true)
            .conflict_style_merge(true)
            .safe()
            .force(), // // For some reason the force is required to make the working directory actually get updated
                      // // I suspect we should be adding some logic to handle dirty working directory states
                      // // but this is just an example so maybe not.
                      // .force(),
    )))?;
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
    let commit_id = if let Some((ref pass, ref key)) = commit_signing_credentials {
        _log(
            Arc::clone(&log_callback),
            LogType::Commit,
            "Signing commit".to_string(),
        );
        let buffer = swl!(repo.commit_create_buffer(
            &author_committer,
            &author_committer,
            message,
            &tree,
            parents,
        ))?;

        let commit = swl!(std::str::from_utf8(&buffer)
            .map_err(|_e| { git2::Error::from_str(&"utf8 conversion error".to_string()) }))?;

        let secret_key = swl!(PrivateKey::from_openssh(key.as_bytes())
            .map_err(|e| git2::Error::from_str(&e.to_string())))?;
        if !pass.is_empty() {
            swl!(secret_key
                .decrypt(pass.as_bytes())
                .map_err(|e| git2::Error::from_str(&e.to_string())))?;
        }
        _log(
            Arc::clone(&log_callback),
            LogType::Commit,
            "Committing".to_string(),
        );
        let sig = swl!(swl!(secret_key
            .sign("git", HashAlg::Sha256, &commit.as_bytes())
            .map_err(|e| git2::Error::from_str(&e.to_string())))?
        .to_pem(LineEnding::LF)
        .map_err(|e| git2::Error::from_str(&e.to_string())))?;

        let commit_id = swl!(repo.commit_signed(commit, &sig, None,))?;

        if let Ok(mut head) = repo.head() {
            swl!(head.set_target(commit_id, message))?;
        } else {
            let current_branch =
                get_branch_name_priv(&repo).unwrap_or_else(|| "master".to_string());

            swl!(repo.reference(
                &format!("refs/heads/{}", current_branch),
                commit_id,
                true,
                message,
            ))?;
        }

        commit_id
    } else {
        _log(
            Arc::clone(&log_callback),
            LogType::Commit,
            "Committing".to_string(),
        );
        swl!(repo.commit(
            update_ref,
            &author_committer,
            &author_committer,
            message,
            &tree,
            parents,
        ))?
    };

    Ok(commit_id.into())
}

pub async fn update_submodules(
    path_string: &str,
    provider: &String,
    credentials: &(String, String),
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::UpdateSubmodules,
        "Getting local directory".to_string(),
    );
    let repo = swl!(Repository::open(&path_string))?;

    _log(
        Arc::clone(&log_callback),
        LogType::UpdateSubmodules,
        "Getting local directory".to_string(),
    );

    tokio::task::block_in_place(|| {
        update_submodules_priv(&repo, &provider, &credentials, &log_callback)
    })
}

fn update_submodules_priv(
    repo: &Repository,
    provider: &String,
    credentials: &(String, String),
    log_callback: &Arc<impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static>,
) -> Result<(), git2::Error> {
    for mut submodule in swl!(repo.submodules())? {
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

        swl!(submodule.update(true, Some(&mut submodule_opts)))?;

        if let Ok(sub_repo) = submodule.open() {
            swl!(sub_repo.checkout_head(Some(
                git2::build::CheckoutBuilder::default()
                    .allow_conflicts(true)
                    .conflict_style_merge(true)
                    .force(),
            )))?;
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
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::FetchRemote,
        "Getting local directory".to_string(),
    );
    let repo = swl!(Repository::open(&path_string))?;

    _log(
        Arc::clone(&log_callback),
        LogType::FetchRemote,
        "Getting local directory".to_string(),
    );

    fetch_remote_priv(&repo, &remote, &provider, &credentials, &log_callback)
}

fn configure_network_timeouts(repo: &Repository) {
    if let Ok(mut config) = repo.config() {
        let _ = config.set_i32("http.lowSpeedLimit", 1000); // 1 KB/s minimum
        let _ = config.set_i32("http.lowSpeedTime", 30); // for 30 consecutive seconds
    }
}

struct StallDetector {
    last_bytes: AtomicU64,
    last_progress_time: Mutex<Instant>,
    stall_timeout_secs: u64,
    stalled: AtomicBool,
}

impl StallDetector {
    fn new(stall_timeout_secs: u64) -> Self {
        Self {
            last_bytes: AtomicU64::new(0),
            last_progress_time: Mutex::new(Instant::now()),
            stall_timeout_secs,
            stalled: AtomicBool::new(false),
        }
    }

    fn check(&self, received_bytes: u64) -> bool {
        let prev = self.last_bytes.swap(received_bytes, Ordering::Relaxed);
        if received_bytes > prev {
            *self.last_progress_time.lock().unwrap() = Instant::now();
            return true;
        }
        let elapsed = self.last_progress_time.lock().unwrap().elapsed().as_secs();
        if elapsed >= self.stall_timeout_secs {
            self.stalled.store(true, Ordering::Relaxed);
            return false; // abort
        }
        true
    }

    fn was_stalled(&self) -> bool {
        self.stalled.load(Ordering::Relaxed)
    }
}

fn fetch_remote_priv(
    repo: &Repository,
    remote: &String,
    provider: &String,
    credentials: &(String, String),
    log_callback: &Arc<impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static>,
) -> Result<Option<bool>, git2::Error> {
    let mut remote = swl!(repo.find_remote(&remote))?;
    configure_network_timeouts(repo);

    let stall_detector = Arc::new(StallDetector::new(30));
    let sd = Arc::clone(&stall_detector);

    let mut callbacks = get_default_callbacks(Some(&provider), Some(&credentials));
    callbacks.transfer_progress(move |stats| sd.check(stats.received_bytes() as u64));

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
    match remote.fetch::<&str>(&[], Some(&mut fetch_options), None) {
        Ok(_) => Ok(Some(true)),
        Err(e) => {
            if stall_detector.was_stalled() {
                Err(git2::Error::from_str(
                    "network stall detected: transfer stalled",
                ))
            } else {
                Err(e)
            }
        }
    }
}

pub async fn pull_changes(
    path_string: &String,
    provider: &String,
    credentials: &(String, String),
    commit_signing_credentials: Option<(String, String)>,
    sync_callback: impl Fn() -> DartFnFuture<()> + Send + Sync + 'static,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<Option<bool>, git2::Error> {
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::PullFromRepo,
        "Getting local directory".to_string(),
    );
    let repo = swl!(Repository::open(&path_string))?;

    _log(
        Arc::clone(&log_callback),
        LogType::PullFromRepo,
        "Getting local directory".to_string(),
    );

    tokio::task::block_in_place(|| {
        pull_changes_priv(
            &repo,
            &provider,
            &credentials,
            commit_signing_credentials,
            sync_callback,
            &log_callback,
        )
    })
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
                return Err(e).map_err(|e| {
                    git2::Error::from_str(&format!("{} (at line {})", e.message(), line!()))
                });
            }
        }
    };

    if result.is_none() {
        return Ok(Some(false));
    }

    let head = result.unwrap();
    let resolved_head = swl!(head.resolve())?;
    let remote_branch = swl!(resolved_head
        .shorthand()
        .ok_or_else(|| git2::Error::from_str("Could not determine branch name")))?;

    let fetch_head = swl!(repo.find_reference("FETCH_HEAD"))?;
    let fetch_commit = swl!(repo.reference_to_annotated_commit(&fetch_head))?;
    let analysis = swl!(repo.merge_analysis(&[&fetch_commit]))?;

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
                if get_staged_file_paths_priv(&repo, &log_callback).is_empty()
                    && get_uncommitted_file_paths_priv(&repo, false, &log_callback).is_empty()
                {
                    swl!(fast_forward(&repo, &mut r, &fetch_commit, &log_callback))?;
                    swl!(update_submodules_priv(
                        &repo,
                        &provider,
                        &credentials,
                        &log_callback
                    ))?;
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
                swl!(repo.reference(
                    &refname,
                    fetch_commit.id(),
                    true,
                    &format!("Setting {} to {}", remote_branch, fetch_commit.id()),
                ))?;
                swl!(repo.set_head(&refname))?;
                swl!(repo.checkout_head(Some(
                    git2::build::CheckoutBuilder::default()
                        .allow_conflicts(true)
                        .conflict_style_merge(true)
                        .force(),
                )))?;
                swl!(update_submodules_priv(
                    &repo,
                    &provider,
                    &credentials,
                    &log_callback
                ))?;
                return Ok(Some(true));
            }
        };
    } else if analysis.0.is_normal() {
        _log(
            Arc::clone(&log_callback),
            LogType::PullFromRepo,
            "Pulling changes".to_string(),
        );
        let head_commit = swl!(repo.reference_to_annotated_commit(&repo.head()?))?;
        _log(
            Arc::clone(&log_callback),
            LogType::PullFromRepo,
            "Normal merge".to_string(),
        );
        let local_tree = swl!(repo.find_commit(head_commit.id())?.tree())?;
        let remote_tree = swl!(repo.find_commit(fetch_commit.id())?.tree())?;
        let ancestor = swl!(swl!(
            repo.find_commit(swl!(repo.merge_base(head_commit.id(), fetch_commit.id()))?)
        )?
        .tree())?;
        let mut idx = swl!(repo.merge_trees(&ancestor, &local_tree, &remote_tree, None))?;

        if idx.has_conflicts() {
            _log(
                Arc::clone(&log_callback),
                LogType::PullFromRepo,
                "Merge conflicts detected".to_string(),
            );

            return Ok(Some(false));
        }
        let result_tree = swl!(repo.find_tree(swl!(idx.write_tree_to(&repo))?))?;
        let msg = format!("Merge: {} into {}", fetch_commit.id(), head_commit.id());
        let sig = swl!(repo.signature())?;
        let local_commit = swl!(repo.find_commit(head_commit.id()))?;
        let remote_commit = swl!(repo.find_commit(fetch_commit.id()))?;
        swl!(commit(
            &repo,
            Some("HEAD"),
            &sig,
            &msg,
            &result_tree,
            &[&local_commit, &remote_commit],
            commit_signing_credentials,
            &log_callback,
        ))?;
        swl!(repo.checkout_head(None))?;
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
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::DownloadChanges,
        "Getting local directory".to_string(),
    );
    let repo = swl!(Repository::open(path_string))?;
    set_author(&repo, &author);
    swl!(repo.cleanup_state())?;

    swl!(fetch_remote_priv(
        &repo,
        &remote,
        &provider,
        &credentials,
        &log_callback
    ))?;

    if tokio::task::block_in_place(|| {
        pull_changes_priv(
            &repo,
            &provider,
            &credentials,
            commit_signing_credentials,
            sync_callback,
            &log_callback,
        )
    }) == Ok(Some(false))
    {
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
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Getting local directory".to_string(),
    );
    let repo = swl!(Repository::open(&path_string))?;

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Getting local directory".to_string(),
    );

    push_changes_priv(
        &repo,
        &remote_name,
        &provider,
        &credentials,
        merge_conflict_callback,
        &log_callback,
    )
}

fn push_changes_priv(
    repo: &Repository,
    remote_name: &String,
    provider: &String,
    credentials: &(String, String),
    merge_conflict_callback: impl Fn() -> DartFnFuture<()> + Send + Sync + 'static,
    log_callback: &Arc<impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static>,
) -> Result<Option<bool>, git2::Error> {
    let mut remote = swl!(repo.find_remote(&remote_name))?;
    configure_network_timeouts(repo);
    let push_error: Arc<Mutex<Option<String>>> = Arc::new(Mutex::new(None));

    let mut callbacks = get_default_callbacks(Some(&provider), Some(&credentials));
    let push_error_clone = Arc::clone(&push_error);
    callbacks.push_update_reference(move |refname, status| {
        if let Some(msg) = status {
            *push_error_clone.lock().unwrap() =
                Some(format!("Remote rejected {}: {}", refname, msg));
        }
        Ok(())
    });

    let mut push_options = PushOptions::new();
    push_options.remote_callbacks(callbacks);

    let result = match repo.head() {
        Ok(h) => Some(h),
        Err(e) => {
            if e.code() == git2::ErrorCode::UnbornBranch {
                None
            } else {
                return Err(e).map_err(|e| {
                    git2::Error::from_str(&format!("{} (at line {})", e.message(), line!()))
                });
            }
        }
    };

    if result.is_none() {
        return Ok(Some(false));
    }

    let git_dir = repo.path();
    let rebase_head_path = git_dir.join("rebase-merge").join("head-name");

    let refname = if rebase_head_path.exists() {
        let content =
            swl!(
                fs::read_to_string(&rebase_head_path).map_err(|err| git2::Error::from_str(
                    &format!("Failed to read rebase head-name file: {}", err)
                ))
            )?;

        content.trim().to_string()
    } else {
        let head = swl!(repo.head())?;
        let resolved_head = swl!(head.resolve())?;
        let branch_name = swl!(resolved_head
            .shorthand()
            .ok_or_else(|| git2::Error::from_str("Could not determine branch name")))?;

        format!("refs/heads/{}", branch_name)
    };

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Pushing changes".to_string(),
    );

    match remote.push(&[&refname], Some(&mut push_options)) {
        Ok(_) => {
            if let Some(err) = push_error.lock().unwrap().take() {
                _log(
                    Arc::clone(&log_callback),
                    LogType::PushToRepo,
                    format!("Push rejected by server: {}", err),
                );
                return Err(git2::Error::from_str(&err));
            }
            _log(
                Arc::clone(&log_callback),
                LogType::PushToRepo,
                "Push successful".to_string(),
            );
        }
        Err(e) if e.code() == ErrorCode::NotFastForward => {
            _log(
                Arc::clone(&log_callback),
                LogType::PushToRepo,
                "Attempting rebase on REJECTED_NONFASTFORWARD".to_string(),
            );

            let head = swl!(repo.head())?;
            let branch_name = swl!(head
                .shorthand()
                .ok_or_else(|| git2::Error::from_str("Invalid branch")))?;

            let remote_branch_ref = format!("refs/remotes/{}/{}", remote_name, branch_name);

            _log(
                Arc::clone(&log_callback),
                LogType::PushToRepo,
                "Attempting rebase on REJECTED_NONFASTFORWARD2".to_string(),
            );

            if repo.state() == RepositoryState::Rebase
                || repo.state() == RepositoryState::RebaseMerge
            {
                let mut rebase = swl!(repo.open_rebase(None))?;
                while let Some(op) = rebase.next() {
                    let commit_id = swl!(op)?.id();
                    let commit = swl!(repo.find_commit(commit_id))?;
                    swl!(rebase.commit(None, &commit.author(), None))?;
                }
                match rebase.finish(None) {
                    Ok(_) => {
                        return Ok(Some(true));
                    }
                    Err(e)
                        if e.code() == ErrorCode::Modified || e.code() == ErrorCode::Unmerged =>
                    {
                        swl!(rebase.abort())?;
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
                        return Err(e).map_err(|e| {
                            git2::Error::from_str(&format!("{} (at line {})", e.message(), line!()))
                        });
                    }
                }
            }

            _log(
                Arc::clone(&log_callback),
                LogType::PushToRepo,
                "Attempting rebase on REJECTED_NONFASTFORWARD3".to_string(),
            );

            if repo.state() != RepositoryState::Clean {
                if let Some(mut rebase) = repo.open_rebase(None).ok() {
                    swl!(rebase.abort())?;
                }
            }

            let remote_branch = swl!(repo.find_reference(&remote_branch_ref))?;
            let annotated_commit = swl!(repo.reference_to_annotated_commit(&remote_branch))?;
            let mut rebase =
                swl!(repo.rebase(None, Some(&annotated_commit), Some(&annotated_commit), None))?;

            while let Some(op) = rebase.next() {
                let commit_id = swl!(op)?.id();
                match rebase.commit(None, &swl!(repo.find_commit(commit_id))?.author(), None) {
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
                        return Err(e).map_err(|e| {
                            git2::Error::from_str(&format!("{} (at line {})", e.message(), line!()))
                        });
                    }
                }
            }

            swl!(rebase.finish(None))?;

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

            let mut callbacks2 = get_default_callbacks(Some(&provider), Some(&credentials));
            let push_error_clone2 = Arc::clone(&push_error);
            callbacks2.push_update_reference(move |refname, status| {
                if let Some(msg) = status {
                    *push_error_clone2.lock().unwrap() =
                        Some(format!("Remote rejected {}: {}", refname, msg));
                }
                Ok(())
            });
            let mut push_options2 = PushOptions::new();
            push_options2.remote_callbacks(callbacks2);

            swl!(remote.push(&[&refname], Some(&mut push_options2)))?;

            if let Some(err) = push_error.lock().unwrap().take() {
                _log(
                    Arc::clone(&log_callback),
                    LogType::PushToRepo,
                    format!("Push rejected by server after rebase: {}", err),
                );
                return Err(git2::Error::from_str(&err));
            }
        }
        Err(e) => {
            return Err(e).map_err(|e| {
                git2::Error::from_str(&format!("{} (at line {})", e.message(), line!()))
            })
        }
    }

    Ok(Some(true))
}

pub async fn stage_file_paths(
    path_string: &String,
    paths: Vec<String>,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Getting local directory".to_string(),
    );
    let repo = swl!(Repository::open(&path_string))?;

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Retrieved Statuses".to_string(),
    );

    let mut index = swl!(repo.index())?;

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Adding Files to Stage".to_string(),
    );

    match index.add_all(paths.iter(), git2::IndexAddOption::DEFAULT, None) {
        Ok(_) => {}
        Err(_) => {
            swl!(index.update_all(paths.iter(), None))?;
        }
    }

    for path in &paths {
        if let Ok(mut sm) = repo.find_submodule(path) {
            let sm_repo = swl!(sm.open())?;
            swl!(sm_repo.index()?.write())?;
            swl!(sm.add_to_index(false))?;
        }
    }

    swl!(index.write())?;

    if !index.has_conflicts() {
        swl!(index.write_tree())?;
    }

    Ok(())
}

pub async fn unstage_file_paths(
    path_string: &String,
    paths: Vec<String>,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    if paths.is_empty() {
        return Ok(());
    }

    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Getting local directory".to_string(),
    );
    let repo = swl!(Repository::open(&path_string))?;

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Retrieved Statuses".to_string(),
    );

    let mut index = swl!(repo.index())?;

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Removing Files from Stage".to_string(),
    );

    let head = swl!(repo.head())?;
    let commit = swl!(head.peel_to_commit())?;
    swl!(repo.reset_default(Some(commit.as_object()), paths.iter()))?;

    swl!(index.write())?;

    if !index.has_conflicts() {
        swl!(index.write_tree())?;
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
    let log_callback = Arc::new(log);
    let repo = swl!(git2::Repository::open(path_string))?;
    let callbacks = get_default_callbacks(Some(&provider), Some(&credentials));
    let branch_name = get_branch_name_priv(&repo).unwrap_or_else(|| "master".to_string());

    if let Ok(mut remote) = repo.find_remote(remote_name) {
        swl!(remote.connect_auth(git2::Direction::Fetch, Some(callbacks), None))?;
        let remote_refs = swl!(remote.list())?;
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
                LogType::RecommendedAction,
                format!(
                    "Recommending action 0: No local tracking reference found. Expected ref: {}",
                    tracking_ref_name
                ),
            );
            return Ok(Some(0));
        }

        if !found {
            _log(
                Arc::clone(&log_callback),
                LogType::RecommendedAction,
                format!("Recommending action 0: Remote reference differs from local tracking reference. Ref: {}", tracking_ref_name)
            );
            return Ok(Some(0));
        }
        remote.disconnect().unwrap();
    }

    if has_local_changes_priv(&repo, &log_callback) {
        _log(
            Arc::clone(&log_callback),
            LogType::RecommendedAction,
            "Recommending action 2: Staged or uncommitted files exist".to_string(),
        );
        return Ok(Some(2));
    }

    if let Ok(head) = repo.head() {
        if let Ok(local_commit) = head.peel_to_commit() {
            if let Ok(remote_branch) = repo.find_branch(
                &format!("{}/{}", remote_name, head.shorthand().unwrap_or("")),
                git2::BranchType::Remote,
            ) {
                if let Ok(remote_commit) = remote_branch.get().peel_to_commit() {
                    if local_commit.id() != remote_commit.id() {
                        let (ahead, behind) =
                            swl!(repo.graph_ahead_behind(local_commit.id(), remote_commit.id()))?;
                        if ahead > 0 {
                            _log(
                                Arc::clone(&log_callback),
                                LogType::RecommendedAction,
                                format!("Recommending action 3: Local branch is ahead of remote by {} commits", ahead)
                            );
                            return Ok(Some(3));
                        } else if behind > 0 {
                            _log(
                                Arc::clone(&log_callback),
                                LogType::RecommendedAction,
                                format!("Recommending action 1: Local branch is behind remote by {} commits", behind)
                            );
                            return Ok(Some(1));
                        }
                        _log(
                            Arc::clone(&log_callback),
                            LogType::RecommendedAction,
                            "Recommending action 3: Unhandled commit difference".to_string(),
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
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Getting local directory".to_string(),
    );
    let repo = swl!(Repository::open(&path_string))?;
    set_author(&repo, &author);

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Retrieved Statuses".to_string(),
    );

    let mut index = swl!(repo.index())?;
    let updated_tree_oid = if !index.has_conflicts() {
        Some(swl!(index.write_tree())?)
    } else {
        None
    };

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Committing changes".to_string(),
    );

    let signature = swl!(repo
        .signature()
        .or_else(|_| Signature::now(&author.0, &author.1)))?;

    let parents = match repo
        .head()
        .ok()
        .and_then(|h| h.resolve().ok())
        .and_then(|h| h.peel_to_commit().ok())
    {
        Some(commit) => vec![commit],
        None => vec![],
    };

    let tree_oid = updated_tree_oid.unwrap_or_else(|| index.write_tree_to(&repo).unwrap());
    let tree = swl!(repo.find_tree(tree_oid))?;

    swl!(commit(
        &repo,
        Some("HEAD"),
        &signature,
        &sync_message,
        &tree,
        &parents.iter().collect::<Vec<_>>(),
        commit_signing_credentials,
        &log_callback,
    ))?;

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
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Getting local directory".to_string(),
    );
    let repo = swl!(Repository::open(&path_string))?;
    set_author(&repo, &author);

    _log(
        Arc::clone(&log_callback),
        LogType::PushToRepo,
        "Retrieved Statuses".to_string(),
    );

    let uncommitted_file_paths: Vec<(String, i32)> =
        get_staged_file_paths_priv(&repo, &log_callback)
            .into_iter()
            .chain(get_uncommitted_file_paths_priv(&repo, true, &log_callback))
            .collect();

    let mut index = swl!(repo.index())?;

    let has_conflicts = index.has_conflicts();
    let initial_tree_oid = if !has_conflicts {
        match swl!(index.write_tree()) {
            Ok(oid) => Some(oid),
            Err(_) => None,
        }
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

    let paths: Vec<String> = if let Some(paths) = file_paths {
        paths
    } else {
        uncommitted_file_paths.into_iter().map(|(p, _)| p).collect()
    };

    match index.add_all(paths.iter(), git2::IndexAddOption::DEFAULT, None) {
        Ok(_) => {}
        Err(_) => {
            let non_submodule_paths: Vec<&String> = paths
                .iter()
                .filter(|path| repo.find_submodule(path).is_err())
                .collect();
            swl!(index.update_all(non_submodule_paths.iter(), None))?;
        }
    }

    for path in &paths {
        if let Ok(mut sm) = repo.find_submodule(path) {
            let sm_repo = swl!(sm.open())?;
            swl!(sm_repo.index()?.write())?;
            swl!(sm.add_to_index(false))?;
        }
    }

    swl!(index.write())?;

    let updated_tree_oid = if !index.has_conflicts() {
        Some(swl!(index.write_tree())?)
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

        let signature = swl!(repo
            .signature()
            .or_else(|_| Signature::now(&author.0, &author.1)))?;

        let parents = match repo
            .head()
            .ok()
            .and_then(|h| h.resolve().ok())
            .and_then(|h| h.peel_to_commit().ok())
        {
            Some(commit) => vec![commit],
            None => vec![],
        };

        let tree_oid = updated_tree_oid.unwrap_or_else(|| index.write_tree_to(&repo).unwrap());
        let tree = swl!(repo.find_tree(tree_oid))?;

        swl!(commit(
            &repo,
            Some("HEAD"),
            &signature,
            &sync_message,
            &tree,
            &parents.iter().collect::<Vec<_>>(),
            commit_signing_credentials,
            &log_callback,
        ))?;
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

    push_changes_priv(
        &repo,
        &remote_name,
        &provider,
        &credentials,
        merge_conflict_callback,
        &log_callback,
    )
}

pub async fn force_pull(
    path_string: String,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<(), git2::Error> {
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::ForcePull,
        "Getting local directory".to_string(),
    );
    let repo = swl!(Repository::open(&path_string))?;
    repo.cleanup_state().unwrap();

    let fetch_commit = swl!(repo
        .find_reference("FETCH_HEAD")
        .and_then(|r| repo.reference_to_annotated_commit(&r)))?;

    let git_dir = repo.path();
    let rebase_head_path = git_dir.join("rebase-merge").join("head-name");
    let refname = if rebase_head_path.exists() {
        let content =
            swl!(
                fs::read_to_string(&rebase_head_path).map_err(|err| git2::Error::from_str(
                    &format!("Failed to read rebase head-name file: {}", err)
                ))
            )?;

        content.trim().to_string()
    } else {
        let head = swl!(repo.head())?;
        let resolved_head = swl!(head.resolve())?;
        let mut branch_name = swl!(resolved_head
            .shorthand()
            .ok_or_else(|| git2::Error::from_str("Could not determine branch name")))?
        .to_string();

        let orig_head_path = git_dir.join("ORIG_HEAD");
        if branch_name == "HEAD" && orig_head_path.exists() {
            let content =
                swl!(
                    fs::read_to_string(&orig_head_path).map_err(|err| git2::Error::from_str(
                        &format!("Failed to read orig_head file: {}", err)
                    ))
                )?;
            let orig_commit_id = content.trim();
            let orig_commit = swl!(repo.find_commit(git2::Oid::from_str(orig_commit_id)?))?;
            let branches = swl!(repo.branches(None))?;

            for branch in branches {
                let (branch_ref, _) = swl!(branch)?;
                let branch_commit = swl!(repo.reference_to_annotated_commit(&branch_ref.get()))?;

                if orig_commit.id() == branch_commit.id() {
                    branch_name = match branch_ref.name() {
                        Ok(Some(name)) => name.to_string(),
                        Ok(None) | Err(_) => {
                            return Err(git2::Error::from_str("Unable to determine branch name"))
                                .map_err(|e| {
                                    git2::Error::from_str(&format!(
                                        "{} (at line {})",
                                        e.message(),
                                        line!()
                                    ))
                                })
                        }
                    };
                    break;
                }
            }
        }

        format!("refs/heads/{}", branch_name)
    };

    let mut reference = swl!(repo.find_reference(&refname))?;
    swl!(reference.set_target(fetch_commit.id(), "force pull"))?;
    swl!(repo.set_head(&refname))?;
    tokio::task::block_in_place(|| {
        swl!(repo.checkout_head(Some(
            git2::build::CheckoutBuilder::new()
                .force()
                .allow_conflicts(true)
                .conflict_style_merge(true),
        )))
    })?;

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
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::ForcePush,
        "Getting local directory".to_string(),
    );
    let repo = swl!(Repository::open(&path_string))?;
    configure_network_timeouts(&repo);

    let mut remote = swl!(repo.find_remote(&remote_name))?;
    let push_error: Arc<Mutex<Option<String>>> = Arc::new(Mutex::new(None));

    let mut callbacks = get_default_callbacks(Some(&provider), Some(&credentials));
    let push_error_clone = Arc::clone(&push_error);
    callbacks.push_update_reference(move |refname, status| {
        if let Some(msg) = status {
            *push_error_clone.lock().unwrap() =
                Some(format!("Remote rejected {}: {}", refname, msg));
        }
        Ok(())
    });

    let mut push_options = PushOptions::new();
    push_options.remote_callbacks(callbacks);

    let git_dir = repo.path();
    let rebase_head_path = git_dir.join("rebase-merge").join("head-name");
    let refname = if rebase_head_path.exists() {
        let content =
            swl!(
                fs::read_to_string(&rebase_head_path).map_err(|err| git2::Error::from_str(
                    &format!("Failed to read rebase head-name file: {}", err)
                ))
            )?;

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
        let head = swl!(repo.head())?;
        let resolved_head = swl!(head.resolve())?;
        let mut branch_name = swl!(resolved_head
            .shorthand()
            .ok_or_else(|| git2::Error::from_str("Could not determine branch name")))?
        .to_string();

        let orig_head_path = git_dir.join("ORIG_HEAD");
        if branch_name == "HEAD" && orig_head_path.exists() {
            let content =
                swl!(
                    fs::read_to_string(&orig_head_path).map_err(|err| git2::Error::from_str(
                        &format!("Failed to read orig_head file: {}", err)
                    ))
                )?;
            let orig_commit_id = content.trim();
            let orig_commit = swl!(repo.find_commit(git2::Oid::from_str(orig_commit_id)?))?;
            let branches = swl!(repo.branches(None))?;

            for branch in branches {
                let (branch_ref, _) = swl!(branch)?;
                let branch_commit = swl!(repo.reference_to_annotated_commit(&branch_ref.get()))?;

                if orig_commit.id() == branch_commit.id() {
                    branch_name = match branch_ref.name() {
                        Ok(Some(name)) => name.to_string(),
                        Ok(None) | Err(_) => {
                            return Err(git2::Error::from_str("Unable to determine branch name"))
                                .map_err(|e| {
                                    git2::Error::from_str(&format!(
                                        "{} (at line {})",
                                        e.message(),
                                        line!()
                                    ))
                                })
                        }
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

    remote.push(&[&refname], Some(&mut push_options))?;

    if let Some(err) = push_error.lock().unwrap().take() {
        _log(
            Arc::clone(&log_callback),
            LogType::ForcePush,
            format!("Force push rejected by server: {}", err),
        );
        return Err(git2::Error::from_str(&err));
    }

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
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::ForcePush,
        "Getting local directory".to_string(),
    );
    let repo = swl!(Repository::open(&path_string))?;
    configure_network_timeouts(&repo);
    set_author(&repo, &author);

    if repo.state() == RepositoryState::Merge
        || repo.state() == RepositoryState::Rebase
        || repo.state() == RepositoryState::RebaseMerge
    {
        let mut rebase = swl!(repo.open_rebase(None))?;
        swl!(rebase.abort())?;
    }

    if !get_staged_file_paths_priv(&repo, &log_callback).is_empty()
        || !get_uncommitted_file_paths_priv(&repo, true, &log_callback).is_empty()
    {
        let mut index = swl!(repo.index())?;

        _log(
            Arc::clone(&log_callback),
            LogType::ForcePush,
            "Adding Files to Stage".to_string(),
        );

        swl!(index.add_all(["*"].iter(), git2::IndexAddOption::DEFAULT, None))?;
        swl!(index.write())?;

        let signature = swl!(repo
            .signature()
            .or_else(|_| Signature::now(&author.0, &author.1)))?;

        let parent_commit = swl!(repo.head()?.resolve()?.peel_to_commit())?;
        let tree_oid = swl!(index.write_tree())?;
        let tree = swl!(repo.find_tree(tree_oid))?;

        _log(
            Arc::clone(&log_callback),
            LogType::ForcePush,
            "Committing changes".to_string(),
        );
        swl!(commit(
            &repo,
            Some("HEAD"),
            &signature,
            &sync_message,
            &tree,
            &[&parent_commit],
            commit_signing_credentials,
            &log_callback,
        ))?;
    }

    let mut remote = swl!(repo.find_remote(&remote_name))?;
    let push_error: Arc<Mutex<Option<String>>> = Arc::new(Mutex::new(None));

    let mut callbacks = get_default_callbacks(Some(&provider), Some(&credentials));
    let push_error_clone = Arc::clone(&push_error);
    callbacks.push_update_reference(move |refname, status| {
        if let Some(msg) = status {
            *push_error_clone.lock().unwrap() =
                Some(format!("Remote rejected {}: {}", refname, msg));
        }
        Ok(())
    });

    let mut push_options = PushOptions::new();
    push_options.remote_callbacks(callbacks);

    let git_dir = repo.path();
    let rebase_head_path = git_dir.join("rebase-merge").join("head-name");
    let refname = if rebase_head_path.exists() {
        let content =
            swl!(
                fs::read_to_string(&rebase_head_path).map_err(|err| git2::Error::from_str(
                    &format!("Failed to read rebase head-name file: {}", err)
                ))
            )?;

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
        let head = swl!(repo.head())?;
        let resolved_head = swl!(head.resolve())?;
        let mut branch_name = swl!(resolved_head
            .shorthand()
            .ok_or_else(|| git2::Error::from_str("Could not determine branch name")))?
        .to_string();

        let orig_head_path = git_dir.join("ORIG_HEAD");
        if branch_name == "HEAD" && orig_head_path.exists() {
            let content =
                swl!(
                    fs::read_to_string(&orig_head_path).map_err(|err| git2::Error::from_str(
                        &format!("Failed to read orig_head file: {}", err)
                    ))
                )?;
            let orig_commit_id = content.trim();
            let orig_commit = swl!(repo.find_commit(git2::Oid::from_str(orig_commit_id)?))?;
            let branches = swl!(repo.branches(None))?;

            for branch in branches {
                let (branch_ref, _) = swl!(branch)?;
                let branch_commit = swl!(repo.reference_to_annotated_commit(&branch_ref.get()))?;

                if orig_commit.id() == branch_commit.id() {
                    branch_name = match branch_ref.name() {
                        Ok(Some(name)) => name.to_string(),
                        Ok(None) | Err(_) => {
                            return Err(git2::Error::from_str("Unable to determine branch name"))
                                .map_err(|e| {
                                    git2::Error::from_str(&format!(
                                        "{} (at line {})",
                                        e.message(),
                                        line!()
                                    ))
                                })
                        }
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

    remote.push(&[&refname], Some(&mut push_options))?;

    if let Some(err) = push_error.lock().unwrap().take() {
        _log(
            Arc::clone(&log_callback),
            LogType::ForcePush,
            format!("Force push rejected by server: {}", err),
        );
        return Err(git2::Error::from_str(&err));
    }

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
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::ForcePull,
        "Getting local directory".to_string(),
    );
    let repo = swl!(Repository::open(&path_string))?;
    set_author(&repo, &author);
    repo.cleanup_state().unwrap();

    let mut remote = swl!(repo.find_remote(&remote_name))?;
    configure_network_timeouts(&repo);

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

    swl!(remote.fetch::<&str>(&[], Some(&mut fetch_options), None))?;

    let fetch_commit = swl!(repo
        .find_reference("FETCH_HEAD")
        .and_then(|r| repo.reference_to_annotated_commit(&r)))?;

    let git_dir = repo.path();
    let rebase_head_path = git_dir.join("rebase-merge").join("head-name");
    let refname = if rebase_head_path.exists() {
        let content =
            swl!(
                fs::read_to_string(&rebase_head_path).map_err(|err| git2::Error::from_str(
                    &format!("Failed to read rebase head-name file: {}", err)
                ))
            )?;

        content.trim().to_string()
    } else {
        let head = swl!(repo.head())?;
        let resolved_head = swl!(head.resolve())?;
        let mut branch_name = swl!(resolved_head
            .shorthand()
            .ok_or_else(|| git2::Error::from_str("Could not determine branch name")))?
        .to_string();

        let orig_head_path = git_dir.join("ORIG_HEAD");
        if branch_name == "HEAD" && orig_head_path.exists() {
            let content =
                swl!(
                    fs::read_to_string(&orig_head_path).map_err(|err| git2::Error::from_str(
                        &format!("Failed to read orig_head file: {}", err)
                    ))
                )?;
            let orig_commit_id = content.trim();
            let orig_commit = swl!(repo.find_commit(git2::Oid::from_str(orig_commit_id)?))?;
            let branches = swl!(repo.branches(None))?;

            for branch in branches {
                let (branch_ref, _) = swl!(branch)?;
                let branch_commit = swl!(repo.reference_to_annotated_commit(&branch_ref.get()))?;

                if orig_commit.id() == branch_commit.id() {
                    branch_name = match branch_ref.name() {
                        Ok(Some(name)) => name.to_string(),
                        Ok(None) | Err(_) => {
                            return Err(git2::Error::from_str("Unable to determine branch name"))
                                .map_err(|e| {
                                    git2::Error::from_str(&format!(
                                        "{} (at line {})",
                                        e.message(),
                                        line!()
                                    ))
                                })
                        }
                    };
                    break;
                }
            }
        }

        format!("refs/heads/{}", branch_name)
    };

    let mut reference = swl!(repo.find_reference(&refname))?;
    swl!(reference.set_target(fetch_commit.id(), "force pull"))?;
    swl!(repo.set_head(&refname))?;
    tokio::task::block_in_place(|| {
        swl!(repo.checkout_head(Some(
            git2::build::CheckoutBuilder::new()
                .force()
                .allow_conflicts(true)
                .conflict_style_merge(true),
        )))
    })?;

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
        LogType::DiscardChanges,
        "Getting local directory".to_string(),
    );
    let repo = swl!(Repository::open(path_string))?;
    let mut index = swl!(repo.index())?;

    for file_path in &file_paths {
        let is_tracked = index.get_path(Path::new(file_path), 0).is_some();

        if is_tracked {
            let mut checkout = git2::build::CheckoutBuilder::new();
            checkout.force();
            checkout.path(file_path);

            tokio::task::block_in_place(|| {
                swl!(repo.checkout_index(Some(&mut index), Some(&mut checkout)))
            })?;
        } else {
            let full_path = Path::new(path_string).join(file_path);

            if full_path.exists() {
                swl!(std::fs::remove_file(&full_path)
                    .map_err(|e| git2::Error::from_str(&format!("Failed to remove file: {}", e))))?;
            }
        }
    }

    Ok(())
}

pub async fn get_conflicting(
    path_string: &String,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Vec<String> {
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::ConflictingFiles,
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
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::StagedFiles,
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
        LogType::StagedFiles,
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

        if path.ends_with('/') && repo.find_submodule(&path[..path.len() - 1]).is_ok() {
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
            }
            Status::INDEX_DELETED => {
                file_paths.push((path.to_string(), 2));
            }
            Status::INDEX_NEW => {
                file_paths.push((path.to_string(), 3));
            }
            _ => {}
        }
    }

    file_paths
}

pub async fn get_uncommitted_file_paths(
    path_string: &str,
    log: impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Vec<(String, i32)> {
    let log_callback = Arc::new(log);

    _log(
        Arc::clone(&log_callback),
        LogType::UncommittedFiles,
        "Getting local directory".to_string(),
    );
    let repo = match Repository::open(path_string) {
        Ok(repo) => repo,
        Err(_) => return Vec::new(),
    };

    _log(
        Arc::clone(&log_callback),
        LogType::UncommittedFiles,
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
    opts.show(git2::StatusShow::Workdir);
    let statuses = repo.statuses(Some(&mut opts)).unwrap();

    let mut file_paths = Vec::new();

    _log(
        Arc::clone(&log_callback),
        LogType::UncommittedFiles,
        "Getting uncommitted file paths".to_string(),
    );

    for entry in statuses.iter() {
        let path = entry.path().unwrap_or_default();
        let status = entry.status();

        if path.ends_with('/') && repo.find_submodule(&path[..path.len() - 1]).is_ok() {
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
            }
            Status::WT_DELETED => {
                file_paths.push((path.to_string(), 2)); // Deletion
            }
            Status::WT_NEW => {
                file_paths.push((path.to_string(), 3)); // Addition
            }
            _ => {}
        }
    }

    file_paths
}

fn has_local_changes_priv(
    repo: &Repository,
    log_callback: &Arc<impl Fn(LogType, String) -> DartFnFuture<()> + Send + Sync + 'static>,
) -> bool {
    _log(
        Arc::clone(&log_callback),
        LogType::RecommendedAction,
        "Checking for local changes".to_string(),
    );

    let mut opts = StatusOptions::new();
    opts.include_untracked(true);
    opts.include_ignored(false);
    opts.update_index(true);
    let statuses = match repo.statuses(Some(&mut opts)) {
        Ok(s) => s,
        Err(_) => return false,
    };

    let index_flags = Status::INDEX_NEW | Status::INDEX_MODIFIED | Status::INDEX_DELETED;
    let wt_flags = Status::WT_NEW | Status::WT_MODIFIED | Status::WT_DELETED;
    let relevant_flags = index_flags | wt_flags;

    for entry in statuses.iter() {
        let path = entry.path().unwrap_or_default();

        if path.ends_with('/') && repo.find_submodule(&path[..path.len() - 1]).is_ok() {
            continue;
        }

        if let Ok(mut submodule) = repo.find_submodule(path) {
            submodule.reload(true).ok();
            let head_oid = submodule.head_id();
            let index_oid = submodule.index_id();
            let workdir_oid = submodule.workdir_id();

            if head_oid != index_oid || head_oid != workdir_oid {
                return true;
            }
            continue;
        }

        if entry.status().intersects(relevant_flags) {
            return true;
        }
    }

    false
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
        let head = swl!(swl!(repo.head())?.peel_to_commit())?;
        swl!(repo.reset(head.as_object(), ResetType::Hard, None))?;
        swl!(repo.cleanup_state())?;
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

        let mut rebase = swl!(repo.open_rebase(None))?;
        swl!(rebase.abort())?;
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
            osshkeys::cipher::Cipher::Null,
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

fn get_branch_name_priv(repo: &Repository) -> Option<String> {
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
        LogType::BranchNames,
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

                if let Some(stripped_name) = name.strip_prefix(&format!("{}/", remote.to_string()))
                {
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
        LogType::SetRemoteUrl,
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
        LogType::CheckoutBranch,
        "Getting local directory".to_string(),
    );
    let repo = Repository::open(Path::new(path_string)).unwrap();
    let branch = match repo.find_branch(&branch_name, git2::BranchType::Local) {
        Ok(branch) => branch,
        Err(e) => {
            if e.code() == ErrorCode::NotFound {
                let remote_branch_name = format!("{}/{}", remote, branch_name);
                let remote_branch =
                    swl!(repo.find_branch(&remote_branch_name, git2::BranchType::Remote))?;
                let target = swl!(remote_branch
                    .get()
                    .target()
                    .ok_or_else(|| git2::Error::from_str("Invalid remote branch")))?;
                swl!(repo.branch(branch_name, &repo.find_commit(target)?, false))?
            } else {
                return Err(e).map_err(|e| {
                    git2::Error::from_str(&format!("{} (at line {})", e.message(), line!()))
                });
            }
        }
    };

    let object = swl!(branch.get().peel(git2::ObjectType::Commit))?;

    let mut checkout_builder = git2::build::CheckoutBuilder::new();
    checkout_builder.force();

    tokio::task::block_in_place(|| swl!(repo.checkout_tree(&object, Some(&mut checkout_builder))))?;

    let refname = format!("refs/heads/{}", branch_name);
    swl!(repo.set_head(&refname))?;

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
        format!(
            "Creating new branch '{}' from '{}'",
            new_branch_name, source_branch_name
        ),
    );

    let repo = swl!(Repository::open(Path::new(path_string)))?;
    configure_network_timeouts(&repo);

    let current_branch = get_branch_name_priv(&repo);

    // If we're not on the source branch, check it out first
    if current_branch.as_deref() != Some(source_branch_name) {
        swl!(
            checkout_branch(
                path_string,
                &remote_name,
                source_branch_name,
                |_level: LogType, _msg: String| Box::pin(async {})
            )
            .await
        )?;
    }

    // Get the commit that the source branch points to
    let source_branch = swl!(repo.find_branch(source_branch_name, BranchType::Local))?;
    let source_commit = swl!(source_branch.get().peel_to_commit())?;

    // Create the new branch pointing to the same commit
    let new_branch = swl!(repo.branch(new_branch_name, &source_commit, false))?;

    _log(
        Arc::clone(&log_callback),
        LogType::Global,
        format!("New branch '{}' created", new_branch_name),
    );

    // Check out the new branch
    let object = swl!(new_branch.get().peel(git2::ObjectType::Commit))?;

    let mut checkout_builder = git2::build::CheckoutBuilder::new();
    checkout_builder.force();

    tokio::task::block_in_place(|| swl!(repo.checkout_tree(&object, Some(&mut checkout_builder))))?;

    let refname = format!("refs/heads/{}", new_branch_name);
    swl!(repo.set_head(&refname))?;

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

    let mut remote = swl!(repo.find_remote(remote_name))?;
    let push_error: Arc<Mutex<Option<String>>> = Arc::new(Mutex::new(None));

    let mut callbacks = get_default_callbacks(Some(provider), Some(credentials));
    let push_error_clone = Arc::clone(&push_error);
    callbacks.push_update_reference(move |refname, status| {
        if let Some(msg) = status {
            *push_error_clone.lock().unwrap() =
                Some(format!("Remote rejected {}: {}", refname, msg));
        }
        Ok(())
    });

    let mut push_options = PushOptions::new();
    push_options.remote_callbacks(callbacks);

    let refspec = format!(
        "refs/heads/{}:refs/heads/{}",
        new_branch_name, new_branch_name
    );

    match remote.push(&[&refspec], Some(&mut push_options)) {
        Ok(_) => {
            if let Some(err) = push_error.lock().unwrap().take() {
                _log(
                    Arc::clone(&log_callback),
                    LogType::PushToRepo,
                    format!("Push rejected by server: {}", err),
                );
                return Err(git2::Error::from_str(&err));
            }
            _log(
                Arc::clone(&log_callback),
                LogType::PushToRepo,
                format!("Successfully pushed branch '{}' to remote", new_branch_name),
            );
        }
        Err(e) => {
            _log(
                Arc::clone(&log_callback),
                LogType::PushToRepo,
                format!(
                    "Failed to push branch '{}' to remote: {}",
                    new_branch_name, e
                ),
            );
            return Err(e).map_err(|e| {
                git2::Error::from_str(&format!("{} (at line {})", e.message(), line!()))
            });
        }
    }

    // Set the upstream branch for the new branch
    let mut branch = swl!(repo.find_branch(new_branch_name, BranchType::Local))?;
    let upstream_name = format!("{}/{}", remote_name, new_branch_name);
    swl!(branch.set_upstream(Some(&upstream_name)))?;

    _log(
        Arc::clone(&log_callback),
        LogType::Global,
        format!(
            "Set upstream for '{}' to '{}'",
            new_branch_name, upstream_name
        ),
    );

    Ok(())
}

pub async fn prune_corrupted_loose_objects(path_string: String) -> Result<(), git2::Error> {
    let repo = swl!(Repository::open(&path_string))?;
    let odb = swl!(repo.odb())?;
    let objects_dir = Path::new(&path_string).join(".git").join("objects");
    let mut pruned = 0u32;

    if !objects_dir.is_dir() {
        return Ok(());
    }

    let entries = match fs::read_dir(&objects_dir) {
        Ok(e) => e,
        Err(_) => return Ok(()),
    };

    for dir_entry in entries.flatten() {
        let dir_name = dir_entry.file_name();
        let dir_name_str = match dir_name.to_str() {
            Some(s) => s,
            None => continue,
        };

        // Only look at 2-char hex prefix directories
        if dir_name_str.len() != 2 || !dir_name_str.chars().all(|c| c.is_ascii_hexdigit()) {
            continue;
        }

        let sub_entries = match fs::read_dir(dir_entry.path()) {
            Ok(e) => e,
            Err(_) => continue,
        };

        for file_entry in sub_entries.flatten() {
            let file_name = file_entry.file_name();
            let file_name_str = match file_name.to_str() {
                Some(s) => s,
                None => continue,
            };

            // Loose object filenames are 38 hex chars
            if file_name_str.len() != 38 || !file_name_str.chars().all(|c| c.is_ascii_hexdigit()) {
                continue;
            }

            let hex = format!("{}{}", dir_name_str, file_name_str);
            let oid = match git2::Oid::from_str(&hex) {
                Ok(o) => o,
                Err(_) => continue,
            };

            if let Err(e) = odb.read_header(oid) {
                let msg = e.message().to_lowercase();
                if msg.contains("failed to parse loose object") {
                    let _ = fs::remove_file(file_entry.path());
                    pruned += 1;
                }
            }
        }
    }

    if pruned > 0 {
        let _ = odb.refresh();
    }

    Ok(())
}
