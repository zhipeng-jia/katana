"""
Betweenness Centrality
----------------------

.. autoclass:: katana.analytics.BetweennessCentralityPlan
    :members:
    :special-members: __init__
    :undoc-members:

.. autoclass:: katana.analytics._betweenness_centrality._BetweennessCentralityAlgorithm

.. autofunction:: katana.analytics.betweenness_centrality

.. autoclass:: katana.analytics.BetweennessCentralityStatistics
    :members:
    :undoc-members:
"""

from libc.stdint cimport uint32_t
from libcpp.string cimport string
from libcpp.vector cimport vector

from katana._property_graph cimport PropertyGraph
from katana.analytics.plan cimport Plan, _Plan
from katana.cpp.libgalois.graphs.Graph cimport _PropertyGraph
from katana.cpp.libstd.iostream cimport ostream, ostringstream
from katana.cpp.libsupport.result cimport Result, handle_result_assert, handle_result_void, raise_error_code

from enum import Enum


cdef extern from "katana/analytics/betweenness_centrality/betweenness_centrality.h" namespace "katana::analytics" nogil:
    cppclass BetweennessCentralitySources:
        pass

    cppclass _BetweennessCentralityPlan "katana::analytics::BetweennessCentralityPlan" (_Plan):
        enum Algorithm:
            kOuter "katana::analytics::BetweennessCentralityPlan::kOuter"
            kLevel "katana::analytics::BetweennessCentralityPlan::kLevel"

        _BetweennessCentralityPlan.Algorithm algorithm() const

        BetweennessCentralityPlan()

        @staticmethod
        _BetweennessCentralityPlan Level()
        @staticmethod
        _BetweennessCentralityPlan Outer()
        @staticmethod
        _BetweennessCentralityPlan FromAlgorithm(_BetweennessCentralityPlan.Algorithm algo)

    BetweennessCentralitySources kBetweennessCentralityAllNodes;

    Result[void] BetweennessCentrality(_PropertyGraph* pg, string output_property_name, const BetweennessCentralitySources& sources, _BetweennessCentralityPlan plan)

    # std_result[void] BetweennessCentralityAssertValid(PropertyGraph* pg, string output_property_name)

    cppclass _BetweennessCentralityStatistics "katana::analytics::BetweennessCentralityStatistics":
        float max_centrality
        float min_centrality
        float average_centrality

        void Print(ostream os)

        @staticmethod
        Result[_BetweennessCentralityStatistics] Compute(_PropertyGraph* pg, string output_property_name)


cdef extern from * nogil:
    """
    katana::analytics::BetweennessCentralitySources BetweennessCentralitySources_from_int(uint32_t v) {
        return v;
    }
    katana::analytics::BetweennessCentralitySources BetweennessCentralitySources_from_vector(std::vector<uint32_t> v) {
        return v;
    }
    """
    BetweennessCentralitySources BetweennessCentralitySources_from_int(uint32_t v)
    BetweennessCentralitySources BetweennessCentralitySources_from_vector(vector[uint32_t] v);


class _BetweennessCentralityAlgorithm(Enum):
    """
    Concrete algorithms for Betweenness Centrality.

    Outer
        Parallelize outermost iteration
    Level
        Process levels in parallel
    """
    Outer = _BetweennessCentralityPlan.Algorithm.kOuter
    Level = _BetweennessCentralityPlan.Algorithm.kLevel


cdef class BetweennessCentralityPlan(Plan):
    """
    A computational :ref:`Plan` for Betweenness Centrality.

    Static method construct BetweennessCentralityPlans using specific algorithms.
    """
    cdef:
        _BetweennessCentralityPlan underlying_

    cdef _Plan* underlying(self) except NULL:
        return &self.underlying_

    Algorithm = _BetweennessCentralityAlgorithm

    @staticmethod
    cdef BetweennessCentralityPlan make(_BetweennessCentralityPlan u):
        f = <BetweennessCentralityPlan>BetweennessCentralityPlan.__new__(BetweennessCentralityPlan)
        f.underlying_ = u
        return f

    @property
    def algorithm(self) -> _BetweennessCentralityAlgorithm:
        return _BetweennessCentralityAlgorithm(self.underlying_.algorithm())

    @staticmethod
    def outer():
        return BetweennessCentralityPlan.make(_BetweennessCentralityPlan.Outer())

    @staticmethod
    def level():
        return BetweennessCentralityPlan.make(_BetweennessCentralityPlan.Level())


def betweenness_centrality(PropertyGraph pg, str output_property_name, sources = None,
             BetweennessCentralityPlan plan = BetweennessCentralityPlan()):
    """
    :type pg: PropertyGraph
    :param pg: The graph to analyze.
    :type output_property_name: str
    :param output_property_name: The output property to write path lengths into. This property must not already exist.
    :type sources: Union[List[int], int]
    :param sources: Only process some sources, producing an approximate betweenness centrality. If this is a list of node IDs process those source nodes; if this is an int process that number of source nodes.
    :type plan: BetweennessCentralityPlan
    :param plan: The execution plan to use.
    """
    output_property_name_bytes = bytes(output_property_name, "utf-8")
    output_property_name_cstr = <string>output_property_name_bytes
    if sources is None:
        c_sources = kBetweennessCentralityAllNodes
    elif isinstance(sources, list) or isinstance(sources, set) or \
            isinstance(sources, tuple) or  isinstance(sources, frozenset):
        c_sources = BetweennessCentralitySources_from_vector(sources)
    else:
        c_sources = BetweennessCentralitySources_from_int(int(sources))
    with nogil:
        handle_result_void(BetweennessCentrality(pg.underlying_property_graph(), output_property_name_cstr,
                                                 c_sources, plan.underlying_))


# def betweenness_centrality_assert_valid(PropertyGraph pg, str output_property_name):
#     output_property_name_bytes = bytes(output_property_name, "utf-8")
#     output_property_name_cstr = <string>output_property_name_bytes
#     with nogil:
#         handle_result_assert(BetweennessCentralityAssertValid(pg.underlying_property_graph(), output_property_name_cstr))


cdef _BetweennessCentralityStatistics handle_result_BetweennessCentralityStatistics(Result[_BetweennessCentralityStatistics] res) nogil except *:
    if not res.has_value():
        with gil:
            raise_error_code(res.error())
    return res.value()


cdef class BetweennessCentralityStatistics:
    """
    Compute the :ref:`statistics` of a Betweenness Centrality computation on a graph.

    All statistics are floats.
    """
    cdef _BetweennessCentralityStatistics underlying

    def __init__(self, PropertyGraph pg, str output_property_name):
        output_property_name_bytes = bytes(output_property_name, "utf-8")
        output_property_name_cstr = <string> output_property_name_bytes
        with nogil:
            self.underlying = handle_result_BetweennessCentralityStatistics(_BetweennessCentralityStatistics.Compute(
                pg.underlying_property_graph(), output_property_name_cstr))

    @property
    def max_centrality(self) -> float:
        return self.underlying.max_centrality

    @property
    def min_centrality(self) -> float:
        return self.underlying.min_centrality

    @property
    def average_centrality(self) -> float:
        return self.underlying.average_centrality

    def __str__(self) -> str:
        cdef ostringstream ss
        self.underlying.Print(ss)
        return str(ss.str(), "ascii")
