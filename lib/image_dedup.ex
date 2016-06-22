defmodule ImageDedup do

  def dedup(path \\ "/Users/aquarhead/Pictures/Other/") do
    {:ok, files} = File.ls(path)

    files
    |> Enum.filter_map(
    &(not String.starts_with? &1, "."),
    &(path <> &1)
    )
    |> Enum.map(&Task.async(__MODULE__, :hash_and_filename, [&1]))
    |> Enum.map(&Task.await(&1))
    |> dedup_via_hash
  end

  def hash_and_filename(filename) do
    {hash_file(filename), filename}
  end

  defp hash_file(filename) do
    :crypto.hash(:sha256, File.read!(filename))
    |> Base.encode16
  end

  defp dedup_via_hash(hashes_filenames) do
    hashes_filenames
    |> Enum.reduce(%{}, fn({hash, filename}, result_map) ->
      {_, next_map} = Map.get_and_update(result_map, hash, &add_filename_to_list(&1, filename))
      next_map
    end
    )
  end

  defp add_filename_to_list(nil, filename), do: {nil, [filename]}
  defp add_filename_to_list(list, filename), do: {list, [filename | list]}

  def list_dup(hash_to_files) do
    hash_to_files
    |> Enum.filter(&(Enum.count(&1) > 1))
  end

end
